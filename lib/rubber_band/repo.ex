defmodule RubberBand.Repo do
  alias __MODULE__
  alias RupperBand.Client
  alias RupperBand.Config
  alias RupperBand.Doc
  alias RupperBand.Stream

  @callback index_exists?(RubberBand.index()) :: boolean

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

      defoverridable Repo
    end
  end

  @spec index_exists?(config :: Config.t(), index :: RubberBand.index()) ::
          boolean
  def index_exists?(config, index) do
    config.adapter.index_exists?(config, index)
  end

  @spec doc_exists?(
          config :: Config.t(),
          index :: RubberBand.index(),
          doc_id :: term
        ) :: boolean
  def doc_exists?(config, index, doc_id) do
    config.adapter.doc_exists?(config, index, doc_id)
  end

  @spec get_doc(
          config :: Config.t(),
          index :: RubberBand.index(),
          doc_id :: term
        ) :: nil | Doc.t()
  def get_doc(config, index, doc_id) do
    config.adapter.get_doc(config, index, doc_id)
  end

  @spec find_doc(
          config :: Config.t(),
          index :: RubberBand.index(),
          search_opts :: RubberBand.search_opts()
        ) :: nil | Doc.t()
  def find_doc(config, index, search_opts \\ %{}) do
    # TODO
  end

  @spec put_doc(
          config :: Config.t(),
          index :: RubberBand.index(),
          doc :: Doc.t()
        ) :: :ok | {:error, RubberBand.error()}
  def put_doc(config, index, doc) do
    put_docs(config, index, [doc])
  end

  @spec put_doc!(
          config :: Config.t(),
          index :: RubberBand.index(),
          doc :: Doc.t()
        ) :: :ok | no_return
  def put_doc!(config, index, doc) do
    put_docs!(config, index, [doc])
  end

  @spec put_docs(
          config :: Config.t(),
          index :: RubberBand.index(),
          docs :: Enum.t() | [Doc.t()]
        ) :: :ok | {:error, RubberBand.error()}
  def put_docs(config, index, docs) do
    config.adapter.put_docs(config, index, docs)
  end

  @spec put_docs!(
          config :: Config.t(),
          index :: RubberBand.index(),
          docs :: Enum.t() | [Doc.t()]
        ) :: :ok | no_return
  def put_docs!(config, index, docs) do
    case put_docs(config, index, search_opts) do
      {:ok, resp} -> resp
      {:error, error} -> raise error
    end
  end

  @spec search(
          config :: Config.t(),
          index :: RubberBand.index(),
          search_opts :: RubberBand.search_opts()
        ) :: {:ok, SearchResult.t()} | {:error, RubberBand.error()}
  def search(config, index, search_opts \\ %{}) do
    config.adapter.search(config, index, search_opts)
  end

  @spec search!(
          config :: Config.t(),
          index :: RubberBand.index(),
          search_opts :: RubberBand.search_opts()
        ) :: SearchResult.t() | no_return
  def search!(config, index, search_opts \\ %{}) do
    case search(config, index, search_opts) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @spec stream_docs(
          config :: Config.t(),
          index :: RubberBand.index(),
          RubberBand.search_opts()
        ) :: Stream.t()
  def stream_docs(config, index, search_opts \\ %{}) do
    %Stream{config: config, index: index, search_opts: search_opts}
  end
end
