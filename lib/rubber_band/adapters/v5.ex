defmodule RubberBand.Adapters.V5 do
  @behaviour RubberBand.Adapter

  alias RubberBand.Client
  alias RubberBand.Doc
  alias RubberBand.Hit
  alias RubberBand.Hits
  alias RubberBand.GetResult
  alias RubberBand.SearchResult

  @type_name "doc"

  @impl true
  def index_exists?(config, index_name) do
    case Client.head(config, index_name) do
      {:ok, %{status_code: 200}} -> true
      _ -> false
    end
  end

  def create_index(config, index_name, settings, mappings) do
    create_index(config, index_name, index_name, settings, mappings)
  end

  @impl true
  def create_index(config, index_name, index_alias, settings, mappings) do
    with :ok <- drop_index(config, index_alias),
         :ok <-
           do_create_index(config, index_name, index_alias, settings, mappings) do
      :ok
    end
  end

  defp do_create_index(config, index_name, index_alias, settings, mappings) do
    opts = %{
      settings: Map.put(settings, :"index.mapping.single_type", true),
      mappings: %{@type_name => mappings},
      aliases: get_alias_opts(index_name, index_alias)
    }

    with {:ok, _} <- Client.put(config, index_name, opts), do: :ok
  end

  defp get_alias_opts(index_name, index_name), do: %{}
  defp get_alias_opts(_index_name, index_alias), do: %{index_alias => %{}}

  @impl true
  def create_and_populate_index(
        config,
        index_name,
        index_alias,
        settings,
        mappings,
        populate_fun
      ) do
    with :ok <-
           do_create_index(config, index_name, index_name, settings, mappings),
         :ok <- populate_index(config, index_name, populate_fun),
         :ok <- create_alias(config, index_name, index_alias) do
      :ok
    end
  end

  defp populate_index(config, index_name, populate_fun) do
    with {:error, error} <- populate_fun.() do
      drop_index(config, index_name)
      {:error, error}
    end
  rescue
    error ->
      drop_index(config, index_name)
      reraise error, __STACKTRACE__
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

    with {:ok, _} <- Client.post(config, "_aliases", opts), do: :ok
  end

  defp recreate_alias(config, index_name, index_alias) do
    opts = %{
      actions: [
        %{remove_index: %{index: index_alias}},
        %{add: %{index: index_name, alias: index_alias}}
      ]
    }

    with {:ok, _} <- Client.post(config, "_aliases", opts), do: :ok
  end

  @impl true
  def drop_index(config, index_name_or_alias) do
    case Client.delete(config, index_name_or_alias) do
      {:ok, _} -> :ok
      {:error, %{status_code: 404}} -> :ok
      error -> error
    end
  end

  @impl true
  def doc_exists?(config, index_name_or_alias, doc_id) do
    case Client.head(config, [index_name_or_alias, @type_name, doc_id]) do
      {:ok, %{status_code: 200}} -> true
      _ -> false
    end
  end

  @impl true
  def get_doc(config, index_name_or_alias, doc_id) do
    case Client.get(config, [index_name_or_alias, @type_name, doc_id]) do
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
    case Client.post(
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
           Client.put(
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
           Client.delete(
             config,
             {[index_name_or_alias, @type_name, doc_id], refresh: "wait_for"}
           ) do
      :ok
    end
  end
end
