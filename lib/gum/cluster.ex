defmodule Gum.Cluster do
  @behaviour Gum.API

  alias __MODULE__
  alias Gum.Config
  alias Gum.ConfigRegistry
  alias Gum.Doc
  alias Gum.MultipleResultsError
  alias Gum.Stream, as: DocStream

  @doc """
  Stores multiple docs in the given index.
  """
  @callback bulk(
              index :: Gum.index_key(),
              operations :: Enum.t() | [Gum.bulk_operation()]
            ) :: {:ok, ESClient.Response.t()} | {:error, Gum.error()}

  @doc """
  Creates an index with the given name and an alias.
  """
  @callback create_index(index :: Gum.index_key()) ::
              :ok | {:error, Gum.error()}

  @doc """
  Creates an index with the given name and a random suffix, then runs the
  callback function and creates an alias on the newly created index.
  """
  @callback create_populated_index(index :: Gum.index_key()) ::
              :ok | {:error, Gum.error()}

  @doc """
  Deletes a single doc from the index.
  """
  @callback delete_doc(
              index :: Gum.index_key(),
              doc_id :: term
            ) :: :ok | {:error, Gum.error()}

  @callback delete_docs(
              index :: Gum.index_key(),
              doc_ids :: [term]
            ) :: :ok | {:error, Gum.error()}

  @doc """
  Deletes multiple docs matching the given predicates.
  """
  @callback delete_docs_by_query(
              index :: Gum.index_key(),
              search_opts :: Gum.search_opts()
            ) :: :ok | {:error, Gum.error()}

  @doc """
  Determines whether the doc with the specified ID exists in the given index.
  """
  @callback doc_exists?(
              index :: Gum.index_key(),
              doc_id :: term
            ) :: boolean

  @doc """
  Drops the index with the given name.
  """
  @callback drop_index(index :: Gum.index_key()) :: :ok | {:error, Gum.error()}

  @doc """
  Gets the doc with the specified ID from the given index. Returns `nil` when no
  doc could be found.
  """
  @callback get_doc(index :: Gum.index_key(), doc_id :: term) ::
              nil | GetResult.t()

  @doc """
  Determines whether the index with the given name exists.
  """
  @callback index_exists?(index :: Gum.index_key()) :: boolean

  @doc """
  Stores a single doc in the given index.
  """
  @callback put_doc(index :: Gum.index_key(), doc :: Doc.t()) ::
              :ok | {:error, Gum.error()}

  @doc """
  Performs a search on the given index.
  """
  @callback search(
              index :: Gum.index_key(),
              search_opts :: Gum.search_opts()
            ) :: {:ok, SearchResult.t()} | {:error, Gum.error()}

  @callback stream_docs(index :: Gum.index_key(), Gum.search_opts()) ::
              Enum.t()

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)

    quote do
      @behaviour Cluster

      @doc false
      @spec __config__() :: Config.t()
      def __config__ do
        ConfigRegistry.lookup(unquote(otp_app), __MODULE__)
      end

      @impl true
      def bulk(index, operations) do
        Cluster.bulk(__config__(), index, operations)
      end

      @impl true
      def index_exists?(index) do
        Cluster.index_exists?(__config__(), index)
      end

      @impl true
      def create_index(index) do
        Cluster.create_index(__config__(), index)
      end

      @impl true
      def create_index!(index) do
        Cluster.create_index!(__config__(), index)
      end

      @impl true
      def create_populated_index(index) do
        Cluster.create_populated_index(__config__(), index)
      end

      @impl true
      def create_populated_index!(index) do
        Cluster.create_populated_index!(__config__(), index)
      end

      @impl true
      def drop_index(index) do
        Cluster.drop_index(__config__(), index)
      end

      @impl true
      def drop_index!(index) do
        Cluster.drop_index!(__config__(), index)
      end

      @impl true
      def doc_exists?(index, doc_id) do
        Cluster.doc_exists?(__config__(), index, doc_id)
      end

      @impl true
      def find_docs(index, search_opts \\ %{}) do
        Cluster.find_docs(__config__(), index, search_opts)
      end

      @impl true
      def find_doc(index, search_opts \\ %{}) do
        Cluster.find_doc(__config__(), index, search_opts)
      end

      @impl true
      def get_doc(index, doc_id) do
        Cluster.get_doc(__config__(), index, doc_id)
      end

      @impl true
      def put_doc(index, doc) do
        Cluster.put_doc(__config__(), index, doc)
      end

      @impl true
      def put_doc!(index, doc) do
        Cluster.put_doc!(__config__(), index, doc)
      end

      @impl true
      def put_docs(index, docs) do
        Cluster.put_docs(__config__(), index, docs)
      end

      @impl true
      def put_docs!(index, docs) do
        Cluster.put_docs!(__config__(), index, docs)
      end

      @impl true
      def search(index, search_opts) do
        Cluster.search(__config__(), index, search_opts)
      end

      @impl true
      def search!(index, search_opts) do
        Cluster.search!(__config__(), index, search_opts)
      end

      defoverridable Cluster
    end
  end

  @impl true
  def index_exists?(config, index) do
    config.api.index_exists?(config, index)
  end

  @impl true
  def create_index(config, index) do
    config.api.create_index(config, index)
  end

  @impl true
  def create_populated_index(config, index) do
    config.api.create_populated_index(config, index)
  end

  @spec create_index!(config :: Config.t(), index :: Gum.index_key()) ::
          :ok | no_return
  def create_index!(config, index) do
    with {:error, error} <- create_index(config, index) do
      raise error
    end
  end

  @spec create_populated_index!(config :: Config.t(), index :: Gum.index_key()) ::
          :ok | no_return
  def create_populated_index!(config, index) do
    with {:error, error} <- create_populated_index(config, index) do
      raise error
    end
  end

  @impl true
  def drop_index(config, index) do
    config.api.drop_index(config, index)
  end

  @spec drop_index!(config :: Config.t(), index :: Gum.index_key()) ::
          :ok | no_return
  def drop_index!(config, index) do
    with {:error, error} <- drop_index(config, index) do
      raise error
    end
  end

  @impl true
  def doc_exists?(config, index, doc_id) do
    config.api.doc_exists?(config, index, doc_id)
  end

  @impl true
  def get_doc(config, index, doc_id) do
    config.api.get_doc(config, index, doc_id)
  end

  @impl true
  def search(config, index, search_opts \\ %{}) do
    config.api.search(config, index, search_opts)
  end

  @spec search!(
          config :: Config.t(),
          index :: Gum.index_key(),
          search_opts :: Gum.search_opts()
        ) :: SearchResult.t() | no_return
  def search!(config, index, search_opts \\ %{}) do
    case search(config, index, search_opts) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @spec find_docs(
          config :: Config.t(),
          index :: Gum.index_key(),
          search_opts :: Gum.search_opts()
        ) :: [Doc.t()]
  def find_docs(config, index, search_opts) do
    # TODO
    []
  end

  @spec find_doc(
          config :: Config.t(),
          index :: Gum.index_key(),
          search_opts :: Gum.search_opts()
        ) :: nil | Doc.t()
  def find_doc(config, index, search_opts) do
    case find_docs(config, index, search_opts) do
      [] -> nil
      [doc] -> doc
      docs -> raise MultipleResultsError, count: length(docs)
    end
  end

  @impl true
  def put_doc(config, index, doc) do
    config.api.put_doc(config, index, doc)
  end

  @spec put_doc!(
          config :: Config.t(),
          index :: Gum.index_key(),
          doc :: Doc.t()
        ) :: :ok | no_return
  def put_doc!(config, index, doc) do
    with {:error, error} <- put_doc(config, index, doc) do
      raise error
    end
  end

  @spec put_docs(
          config :: Config.t(),
          index :: Gum.index_key(),
          docs :: Enum.t() | [Doc.t()]
        ) :: :ok | {:error, Gum.error()}
  def put_docs(config, index, docs) do
    with {:ok, _} <- bulk(config, index, Stream.map(docs, &{:index, &1})) do
      :ok
    end
  end

  @spec put_docs!(
          config :: Config.t(),
          index :: Gum.index_key(),
          docs :: Enum.t() | [Doc.t()]
        ) :: :ok | no_return
  def put_docs!(config, index, docs) do
    with {:error, error} <- put_docs(config, index, docs) do
      raise error
    end
  end

  @impl true
  def delete_doc(config, index, doc_id) do
    config.api.delete_doc(config, index, doc_id)
  end

  @impl true
  def delete_docs_by_query(config, index, search_opts) do
    config.api.delete_docs_by_query(config, index, search_opts)
  end

  @impl true
  def bulk(config, index, operations) do
    config.api.bulk(config, index, operations)
  end

  @spec delete_docs(
          config :: Config.t(),
          index :: Gum.index_key(),
          doc_ids :: [term]
        ) :: :ok | {:error, Gum.error()}
  def delete_docs(config, index, doc_ids) do
    with {:ok, _} <- bulk(config, index, Stream.map(doc_ids, &{:delete, &1})) do
      :ok
    end
  end

  @spec stream_docs(
          config :: Config.t(),
          index :: Gum.index_key(),
          Gum.search_opts()
        ) :: Enum.t()
  def stream_docs(config, index, search_opts \\ %{}) do
    %DocStream{config: config, index: index, search_opts: search_opts}
  end
end
