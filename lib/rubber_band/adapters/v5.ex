defmodule RubberBand.Adapters.V5 do
  @moduledoc """
  The primary namespace for all search related functions.
  """

  @behaviour RubberBand.Adapter

  alias RubberBand.Doc
  alias RubberBand.SearchResult

  @type_name "doc"

  # Indexes

  @impl true
  def index_exists?(context) do
    index_or_alias_exists?(context.config.client, context.index_name)
  end

  defp index_or_alias_exists?(client, index_name) do
    case client.head(index_name) do
      {:ok, %{status_code: 200}} -> true
      _ -> false
    end
  end

  @impl true
  def create_index(context) do
    # Dropping the alias references before creating a new one. This prevents the
    # alias from referencing multiple indexes at the same time.
    drop_index(context)

    # Create the new index and instantly set the alias.
    do_create_index(context, %{aliases: %{context.index_name => %{}}})
  end

  # @impl true
  # def create_populated_index(index) do
  #   store = fetch_store!(index)
  #   alias_name = prefix_index_name(index)
  #   index_name = generate_index_name(alias_name)

  #   with :ok <- do_create_index(index_name, store),
  #        :ok <- do_populate_index(index_name, store),
  #        :ok <- create_alias(index_name, alias_name) do
  #     :ok
  #   end
  # end

  defp do_create_index(context, additional_data \\ %{}) do
    index_name = generate_index_name(context.index_name)

    data =
      Map.merge(
        %{
          settings:
            Map.put(
              context.index_mod.settings(),
              :"index.mapping.single_type",
              true
            ),
          mappings: %{
            context.config.default_type_name => context.index_mod.mapping()
          }
        },
        additional_data
      )

    with {:ok, _} <- context.client.put(index_name, data) do
      :ok
    end
  end

  # defp create_alias(index_name, alias_name) do
  #   if index_or_alias_exists?(alias_name) do
  #     recreate_alias(index_name, alias_name)
  #   else
  #     create_new_alias(index_name, alias_name)
  #   end
  # end

  # defp create_new_alias(index_name, alias_name) do
  #   "_aliases"
  #   |> HTTP.post(%{
  #     actions: [
  #       %{remove: %{index: :_all, alias: alias_name}},
  #       %{add: %{index: index_name, alias: alias_name}}
  #     ]
  #   })
  #   |> case do
  #     {:ok, _} -> :ok
  #     error -> error
  #   end
  # end

  # defp recreate_alias(index_name, alias_name) do
  #   "_aliases"
  #   |> HTTP.post(%{
  #     actions: [
  #       %{remove_index: %{index: alias_name}},
  #       %{add: %{index: index_name, alias: alias_name}}
  #     ]
  #   })
  #   |> case do
  #     {:ok, _} -> :ok
  #     error -> error
  #   end
  # end

  defp generate_index_name(index_name) do
    "#{index_name}-#{UUID.uuid4()}"
  end

  @impl true
  def drop_index(context) do
    case context.config.client.delete(context.index_name) do
      {:ok, _} ->
        :ok

      {:error, %{status_code: 404}} ->
        # Just to behave similar to document deletion
        :ok

      error ->
        error
    end
  end

  # @impl true
  # def populate_index(index) do
  #   index_name = prefix_index_name(index)
  #   store = fetch_store!(index)

  #   case do_populate_index(index_name, store) do
  #     :ok -> :ok
  #     _ -> :error
  #   end
  # end

  # defp do_populate_index(index_name, store) do
  #   fn ->
  #     for source <- store.sources(), query = Queryable.to_query(source) do
  #       populate_index_by_source_and_query(index_name, store, source, query)
  #     end
  #   end
  #   |> Repo.transaction(timeout: :infinity)
  #   |> case do
  #     {:ok, _} -> :ok
  #     _ -> {:error, :index_population_error}
  #   end
  # end

  # defp populate_index_by_source_and_query(index_name, store, source, query) do
  #   source
  #   |> store.populate_query(query)
  #   |> Repo.stream(max_rows: store.bulk_size())
  #   |> Stream.chunk_every(store.bulk_size())
  #   |> Stream.map(&do_put_records(&1, index_name, store))
  #   |> Stream.run()
  # end

  # Documents

  @impl true
  def doc_exists?(context, id) do
    "#{context.index_name}/#{@type_name}/#{id}"
    |> context.config.client.head()
    |> case do
      {:ok, %{status_code: 200}} -> true
      _ -> false
    end
  end

  @impl true
  def get_doc(context, id) do
    "#{context.index_name}/#{@type_name}/#{id}"
    |> context.config.client.get()
    |> case do
      {:ok, %{status_code: 200, body: body}} ->
        Doc.load(body, context.index_mod)

      _ ->
        nil
    end
  end

  @impl true
  def search(context, search_opts) do
    with {:ok, resp} <-
           context.config.client.post(
             "#{context.index_name}/#{@type_name}/_search",
             search_opts
           ) do
      {:ok, %SearchResult{resp: resp, index_mod: context.index_mod}}
    end
  end

  @impl true
  def put_records(context, data, await) do
    # do_put_records(records, index_name, store)
  end

  # defp do_put_records(records, index_name, store) do
  #   store
  #   |> Store.dump_records(records)
  #   |> put_docs(index_name, store)
  #   |> case do
  #     {:ok, _} -> :ok
  #     error -> error
  #   end
  # end

  # defp put_docs([], _index_name, _store), do: {:ok, nil}

  # defp put_docs([data], index_name, store) do
  #   id = store.doc_id(data)

  #   HTTP.put(
  #     "#{index_name}/#{@type_name}/#{id}?refresh=wait_for",
  #     data
  #   )
  # end

  # defp put_docs(data_list, index_name, store) do
  #   HTTP.post(
  #     "#{index_name}/#{@type_name}/_bulk?refresh=wait_for",
  #     build_bulk_payload(data_list, store)
  #   )
  # end

  # defp build_bulk_payload(data_list, store) do
  #   data_list
  #   |> Stream.flat_map(fn data ->
  #     id = store.doc_id(data)
  #     [%{index: %{_id: id}}, data]
  #   end)
  #   |> Stream.map(&json_library().encode!/1)
  #   |> Enum.join("\n")
  #   |> Kernel.<>("\n")
  # end

  @impl true
  def delete_doc(context, id, await) do
    "#{context.index_name}/#{@type_name}/#{id}"
    |> add_wait_for_refresh_param_to_url(await)
    |> context.config.client.delete(id)
    |> case do
      {:ok, _} -> :ok
      error -> error
    end
  end

  defp add_wait_for_refresh_param_to_url(url, true) do
    %{URI.parse(url) | query: "refresh=wait_for"}
  end

  defp add_wait_for_refresh_param_to_url(url, false), do: url

  @impl true
  def delete_docs_by_query(context, search_opts, await) do
    "#{context.index_name}/#{@type_name}/_delete_by_query"
    |> add_delete_by_query_await_param(await)
    |> context.config.client.post(search_opts)
    |> case do
      {:ok, _} -> :ok
      error -> error
    end
  end

  defp add_delete_by_query_await_param(url, true) do
    %{URI.parse(url) | query: "wait_for_completion=true"}
  end

  defp add_delete_by_query_await_param(url, false), do: url
end
