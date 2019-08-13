defmodule RubberBand.Index do
  @moduledoc """
  A behavior to define a search index.
  """

  alias RubberBand.Doc

  @typedoc """
  A map that contains arbitrary values that are fetched before dumping
  particular records.
  """
  @type context :: %{optional(atom) => any}

  @typedoc """
  Type definition for a source module.
  """
  @type source :: module

  @typedoc """
  Type definition for an index identifier.
  """
  @type key :: atom

  @typedoc """
  Type definition for a store module.
  """
  @type mod :: module

  @doc """
  A map containing index settings.
  """
  @callback settings() :: %{optional(atom) => any}

  @doc """
  The index mapping.
  """
  @callback mapping() :: %{optional(atom) => any}

  @doc """
  A list of sources to use when fetching.
  """
  @callback sources() :: [source]

  @doc """
  Callback that is invoked when deserializing a document that has just been
  retrieved from the search index. Can be used to transform the result to your
  particular needs.
  """
  @callback load(doc :: Doc.t()) :: any

  @doc """
  A callback that is called before dumping any record. The function is only
  invoked once per source.
  """
  @callback dump_context(source) :: context

  @doc """
  Callback that is used when serializing a record to store it in a search index.
  You can transform the record data here so that it fits your needs. When
  returning a list here, multiple documents are inserted to the database. Note
  that you should most likely define your own implementation of `doc_id/1` in
  these cases.
  """
  @callback dump(record :: any, context) :: Doc.t() | [Doc.t()]

  defmacro __using__(opts \\ []) do
    quote do
      @behaviour unquote(__MODULE__)

      @default_sources unquote(opts[:sources]) || []

      @impl true
      def settings, do: %{}

      @impl true
      def mapping, do: %{}

      @impl true
      def sources, do: @default_sources

      @impl true
      def doc_id(doc) do
        doc
        |> Map.fetch!(:id)
        |> to_string()
      end

      @impl true
      def load(doc), do: doc

      @impl true
      def dump_context(_source), do: %{}

      @impl true
      def dump(data, _context), do: data

      # Allow overriding all functions defined by the behavior
      defoverridable unquote(__MODULE__)
    end
  end

  # @doc """
  # Gets the doc IDs for the given record or records.
  # """
  # @spec doc_ids(store, any | [any]) :: [term]
  # def doc_ids(store, record_or_records)

  # def doc_ids(store, records) when is_list(records) do
  #   store
  #   |> dump_records(records)
  #   |> Enum.map(&store.doc_id/1)
  # end

  # def doc_ids(store, record) do
  #   doc_ids(store, [record])
  # end

  # @doc """
  # Dumps a single record for storage in the given store.
  # """
  # @spec dump_record(store, any) :: [Doc.t]
  # def dump_record(store, record) do
  #   dump_records(store, [record])
  # end

  # @doc """
  # Dumps multiple records for storage in the given store.
  # """
  # @spec dump_records(store, [any]) :: [Doc.t]
  # def dump_records(store, records) do
  #   sources = store.sources()

  #   records
  #   |> Enum.filter(&(&1.__struct__ in sources))
  #   |> Enum.group_by(& &1.__struct__)
  #   |> Enum.flat_map(fn {source, records_from_source} ->
  #     dump_record_by_source(store, source, records_from_source)
  #   end)
  # end

  # defp dump_record_by_source(store, source, records) do
  #   dump_context = store.dump_context(source)

  #   records
  #   |> preload_records(store.preloads(source))
  #   |> Enum.flat_map(&do_dump_record(store, dump_context, &1))
  # end

  # defp do_dump_record(store, dump_context, record) do
  #   record
  #   |> store.dump(dump_context)
  #   |> List.wrap()
  # end

  # defp preload_records(records, nil), do: records

  # defp preload_records(records, []), do: records

  # defp preload_records(records, preloads) do
  #   # There is an issue when preloading associations of multiple records that
  #   # have already been preloaded: Ecto adds some records multiple times to
  #   # the has_many association. Try it out with the following command before and
  #   # after preloading:
  #   #
  #   # IO.inspect(Enum.map(records, &length(&1.product.family.bundlings)))

  #   Repo.preload(records, preloads)
  # end
end
