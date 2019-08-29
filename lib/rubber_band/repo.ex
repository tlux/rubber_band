defmodule RubberBand.Repo do
  alias __MODULE__
  alias RubberBand.Config
  alias RubberBand.Doc
  alias RubberBand.Index
  alias RubberBand.MultipleResultsError
  alias RubberBand.Stream, as: DocStream
  alias RubberBand.UnknownIndexError

  @callback index_exists?(Index.index_key()) :: boolean | no_return

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)

    quote do
      @behaviour Repo

      @doc false
      @spec __config__() :: Config.t()
      def __config__ do
        unquote(otp_app)
        |> Application.get_env(__MODULE__, [])
        |> Config.new()
      end

      @impl true
      def index_exists?(index) do
        Repo.index_exists?(__config__(), index)
      end

      @impl true
      def create_index(index, callback_fun \\ nil) do
        Repo.create_index(__config__(), index, callback_fun)
      end

      @impl true
      def create_index!(index, callback_fun \\ nil) do
        Repo.create_index!(__config__(), index, callback_fun)
      end

      @impl true
      def drop_index(index) do
        Repo.drop_index(__config__(), index)
      end

      @impl true
      def drop_index!(index) do
        Repo.drop_index!(__config__(), index)
      end

      @impl true
      def doc_exists?(index, doc_id) do
        Repo.doc_exists?(__config__(), index, doc_id)
      end

      @impl true
      def get_doc(index, doc_id) do
        Repo.get_doc(__config__(), index, doc_id)
      end

      @impl true
      def find_docs(index, search_opts \\ %{}) do
        Repo.find_docs(__config__(), index, search_opts)
      end

      @impl true
      def find_doc(index, search_opts \\ %{}) do
        Repo.find_doc(__config__(), index, search_opts)
      end

      @impl true
      def put_doc(index, doc) do
        Repo.put_doc(__config__(), index, doc)
      end

      @impl true
      def put_doc!(index, doc) do
        Repo.put_doc!(__config__(), index, doc)
      end

      @impl true
      def put_docs(index, docs) do
        Repo.put_docs(__config__(), index, docs)
      end

      @impl true
      def put_docs!(index, docs) do
        Repo.put_docs!(__config__(), index, docs)
      end

      @impl true
      def search(index, search_opts) do
        Repo.search(__config__(), index, search_opts)
      end

      @impl true
      def search!(index, search_opts) do
        Repo.search!(__config__(), index, search_opts)
      end

      defoverridable Repo
    end
  end

  @spec index_exists?(config :: Config.t(), index :: Index.index_key()) ::
          boolean | no_return
  def index_exists?(config, index) do
    index_name = fetch_index_name!(config, index)
    config.adapter.index_exists?(config, index_name)
  end

  @spec create_index(
          config :: Config.t(),
          index :: Index.index_key(),
          populate_fun :: nil | (() -> :ok | {:error, any})
        ) :: :ok | {:error, RubberBand.error()}
  def create_index(config, index, populate_fun \\ nil) do
    with {:ok, index_name} <- fetch_index_name(config, index) do
      config.adapter.create_index(config, index_name, populate_fun)
    end
  end

  @spec create_index!(
          config :: Config.t(),
          index :: Index.index_key(),
          populate_fun :: nil | (() -> :ok | {:error, any})
        ) :: :ok | no_return
  def create_index!(config, index, populate_fun \\ nil) do
    with {:error, error} <- create_index(config, index, populate_fun) do
      raise error
    end
  end

  @spec drop_index(config :: Config.t(), index :: Index.index_key()) ::
          :ok | {:error, RubberBand.error()}
  def drop_index(config, index) do
    with {:ok, index_name} <- fetch_index_name(config, index) do
      config.adapter.drop_index(config, index_name)
    end
  end

  @spec drop_index!(config :: Config.t(), index :: Index.index_key()) ::
          :ok | no_return
  def drop_index!(config, index) do
    with {:error, error} <- drop_index(config, index) do
      raise error
    end
  end

  @spec doc_exists?(
          config :: Config.t(),
          index :: Index.index_key(),
          doc_id :: term
        ) :: boolean | no_return
  def doc_exists?(config, index, doc_id) do
    index_name = fetch_index_name!(config, index)
    config.adapter.doc_exists?(config, index_name, doc_id)
  end

  @spec get_doc(
          config :: Config.t(),
          index :: Index.index_key(),
          doc_id :: term
        ) :: nil | Doc.t() | no_return
  def get_doc(config, index, doc_id) do
    index_name = fetch_index_name!(config, index)
    config.adapter.get_doc(config, index_name, doc_id)
  end

  @spec search(
          config :: Config.t(),
          index :: Index.index_key(),
          search_opts :: RubberBand.search_opts()
        ) :: {:ok, SearchResult.t()} | {:error, RubberBand.error()}
  def search(config, index, search_opts \\ %{}) do
    with {:ok, index_name} <- fetch_index_name(config, index) do
      config.adapter.search(config, index_name, search_opts)
    end
  end

  @spec search!(
          config :: Config.t(),
          index :: Index.index_key(),
          search_opts :: RubberBand.search_opts()
        ) :: SearchResult.t() | no_return
  def search!(config, index, search_opts \\ %{}) do
    case search(config, index, search_opts) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @spec find_docs(
          config :: Config.t(),
          index :: Index.index_key(),
          search_opts :: RubberBand.search_opts()
        ) :: [Doc.t()]
  def find_docs(config, index, search_opts) do
    # TODO
    []
  end

  @spec find_doc(
          config :: Config.t(),
          index :: Index.index_key(),
          search_opts :: RubberBand.search_opts()
        ) :: nil | Doc.t()
  def find_doc(config, index, search_opts) do
    case find_docs(config, index, search_opts) do
      [] -> nil
      [doc] -> doc
      docs -> raise MultipleResultsError, count: length(docs)
    end
  end

  @spec put_doc(
          config :: Config.t(),
          index :: Index.index_key(),
          doc :: Doc.t()
        ) :: :ok | {:error, RubberBand.error()}
  def put_doc(config, index, doc) do
    with {:ok, index_name} <- fetch_index_name(config, index) do
      config.adapter.put_doc(config, index_name, doc)
    end
  end

  @spec put_doc!(
          config :: Config.t(),
          index :: Index.index_key(),
          doc :: Doc.t()
        ) :: :ok | no_return
  def put_doc!(config, index, doc) do
    with {:error, error} <- put_doc(config, index, doc) do
      raise error
    end
  end

  @spec put_docs(
          config :: Config.t(),
          index :: Index.index_key(),
          docs :: Enum.t() | [Doc.t()]
        ) :: :ok | {:error, RubberBand.error()}
  def put_docs(config, index, docs) do
    with {:ok, _} <- bulk(config, index, Stream.map(docs, &{:index, &1})) do
      :ok
    end
  end

  @spec put_docs!(
          config :: Config.t(),
          index :: Index.index_key(),
          docs :: Enum.t() | [Doc.t()]
        ) :: :ok | no_return
  def put_docs!(config, index, docs) do
    with {:error, error} <- put_docs(config, index, docs) do
      raise error
    end
  end

  @spec delete_doc(
          config :: Config.t(),
          index :: Index.index_key(),
          doc_id :: term
        ) :: :ok | {:error, RubberBand.error()}
  def delete_doc(config, index, doc_id) do
    with {:ok, index_name} <- fetch_index_name(config, index) do
      config.adapter.delete_doc(config, index_name, doc_id)
    end
  end

  @spec delete_docs(
          config :: Config.t(),
          index :: Index.index_key(),
          doc_ids :: [term]
        ) :: :ok | {:error, RubberBand.error()}
  def delete_docs(config, index, doc_ids) do
    with {:ok, _} <- bulk(config, index, Stream.map(doc_ids, &{:delete, &1})) do
      :ok
    end
  end

  @spec delete_docs_by_query(
          config :: Config.t(),
          index :: Index.index_key(),
          search_opts :: RubberBand.search_opts()
        ) :: :ok | {:error, RubberBand.error()}
  def delete_docs_by_query(config, index, search_opts) do
    with {:ok, index_name} <- fetch_index_name(config, index) do
      config.adapter.delete_docs_by_query(config, index_name, search_opts)
    end
  end

  @spec bulk(
          config :: Config.t(),
          index :: Index.index_key(),
          operations :: [RubberBand.bulk_operation()]
        ) :: {:ok, ESClient.Response.t()} | {:error, RubberBand.error()}
  def bulk(config, index, operations) do
    with {:ok, index_name} <- fetch_index_name(config, index) do
      config.adapter.bulk(config, index_name, operations)
    end
  end

  @spec stream_docs(
          config :: Config.t(),
          index :: Index.index_key(),
          RubberBand.search_opts()
        ) :: Stream.t()
  def stream_docs(config, index, search_opts \\ %{}) do
    %DocStream{config: config, index: index, search_opts: search_opts}
  end

  defp fetch_index_name!(config, index) do
    case fetch_index_name(config, index) do
      {:ok, index_name} -> index_name
      {:error, error} -> raise error
    end
  end

  defp fetch_index_name(config, index) do
    if Map.has_key?(config.indices, index) do
      {:ok, prefix_index_name(index, config.index_prefix)}
    else
      {:error, %UnknownIndexError{index: index}}
    end
  end

  defp prefix_index_name(index, nil), do: to_string(index)
  defp prefix_index_name(index, prefix), do: "#{prefix}#{index}"
end
