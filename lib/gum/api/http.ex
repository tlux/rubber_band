defmodule Gum.API.HTTP do
  @behaviour Gum.API

  import Gum.Config, only: [fetch_index: 2]

  alias Gum.Doc
  alias Gum.GetResult
  alias Gum.Hit
  alias Gum.Hits
  alias Gum.SearchResult

  @impl true
  def index_exists?(config, index) do
    with {:ok, index_name, _store_mod} <- fetch_index(config, index),
         {:ok, %{status_code: 200}} <- ESClient.head(config.client, index_name) do
      true
    else
      _ -> false
    end
  end

  @impl true
  def create_index(config, index) do
    with {:ok, index_alias, store_mod} <- fetch_index(config, index),
         :ok <- drop_index(config, index_alias),
         {:ok, _} <- do_create_index(config, index_alias, store_mod) do
      :ok
    end
  end

  defp do_create_index(config, index_alias, store_mod) do
    index_name = generate_index_name(index_alias)

    opts = %{
      settings: get_settings_opts(store_mod.settings(), config.type_name),
      mappings: get_mappings_opts(store_mod.mappings(), config.type_name),
      aliases: get_alias_opts(index_name, index_alias)
    }

    with {:ok, _} <- ESClient.put(config, index_name, opts) do
      {:ok, index_name}
    end
  end

  defp get_settings_opts(settings, nil), do: settings

  defp get_settings_opts(settings, _type_name) do
    Map.put(settings, :"index.mapping.single_type", true)
  end

  defp get_mappings_opts(mappings, nil), do: mappings
  defp get_mappings_opts(mappings, type_name), do: %{type_name => mappings}

  defp get_alias_opts(index_name, index_name), do: %{}
  defp get_alias_opts(_index_name, index_alias), do: %{index_alias => %{}}

  defp generate_index_name(index_alias) do
    timestamp = :os.system_time(:millisecond)
    "#{index_alias}-#{timestamp}"
  end

  @impl true
  def create_populated_index(config, index) do
    with {:ok, index_alias, store_mod} <- fetch_index(config, index),
         {:ok, index_name} <- do_create_index(config, index_alias, store_mod),
         :ok <- populate_index(config, index_name, store_mod),
         :ok <- create_alias(config, index_name, index_alias) do
      :ok
    end
  end

  defp populate_index(config, index_name, store_mod) do
    store_mod.populate_transaction(fn ->
      nil
      # store_mod.populate_stream
    end)
  end

  defp create_alias(config, index_name, index_alias) do
    if index_exists?(config, index_alias) do
      recreate_alias(config, index_name, index_alias)
    else
      create_new_alias(config, index_name, index_alias)
    end
  end

  defp create_new_alias(config, index_name, index_alias) do
    opts = %{
      actions: [
        %{remove: %{index: :_all, alias: index_alias}},
        %{add: %{index: index_name, alias: index_alias}}
      ]
    }

    with {:ok, _} <- ESClient.post(config, "_aliases", opts), do: :ok
  end

  defp recreate_alias(config, index_name, index_alias) do
    opts = %{
      actions: [
        %{remove_index: %{index: index_alias}},
        %{add: %{index: index_name, alias: index_alias}}
      ]
    }

    with {:ok, _} <- ESClient.post(config, "_aliases", opts), do: :ok
  end

  @impl true
  def drop_index(config, index_name_or_alias) do
    case ESClient.delete(config, index_name_or_alias) do
      {:ok, _} -> :ok
      {:error, %{status_code: 404}} -> :ok
      error -> error
    end
  end

  @impl true
  def doc_exists?(config, index_name_or_alias, doc_id) do
    case ESClient.head(config, [index_name_or_alias, @type_name, doc_id]) do
      {:ok, %{status_code: 200}} -> true
      _ -> false
    end
  end

  @impl true
  def get_doc(config, index_name_or_alias, doc_id) do
    case ESClient.get(config, [index_name_or_alias, @type_name, doc_id]) do
      {:ok, %{data: data}} ->
        %GetResult{
          doc: %{id: data._id, source: data._source},
          version: data._version
        }

      {:error, %{status_code: 404}} ->
        nil

      {:error, error} ->
        raise error
    end
  end

  @impl true
  def search(config, index_name_or_alias, search_opts) do
    case ESClient.post(
           config,
           [index_name_or_alias, @type_name, "_search"],
           search_opts
         ) do
      {:ok, resp} ->
        entries =
          Enum.map(resp.data.hits.hits, fn hit ->
            %Hit{doc: %Doc{id: hit._id, source: hit._source}, score: hit._score}
          end)

        total = resp.data.hits.total
        max_score = resp.data.hits.max_score

        {:ok,
         %SearchResult{
           hits: %Hits{entries: entries, total: total, max_score: max_score}
         }}

      {:error, error} ->
        {:error, error}
    end
  end

  @impl true
  def put_doc(config, index_name_or_alias, doc) do
    with {:ok, _} <-
           ESClient.put(
             config,
             {[index_name_or_alias, @type_name, doc.id], refresh: "wait_for"},
             doc.source
           ) do
      :ok
    end
  end

  @impl true
  def delete_doc(config, index_name_or_alias, doc_id) do
    with {:ok, _} <-
           ESClient.delete(
             config,
             {[index_name_or_alias, @type_name, doc_id], refresh: "wait_for"}
           ) do
      :ok
    end
  end
end
