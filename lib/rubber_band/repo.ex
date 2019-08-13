defmodule RubberBand.Repo do
  alias RubberBand.AdapterContext
  alias RubberBand.Config
  alias RubberBand.Index
  alias RubberBand.SearchResult

  @callback index_exists?(index_key :: Index.key()) :: boolean

  @callback create_index(index_key :: Index.key()) ::
              :ok | {:error, RubberBand.error()}

  @callback drop_index(index_key :: Index.key()) ::
              :ok | {:error, RubberBand.error()}

  @callback doc_exists?(index_key :: Index.key()) :: boolean

  @callback get_doc(index_key :: Index.key(), id :: term) :: nil | Hit.t()

  @callback search(
              index_key :: Index.key(),
              search_opts :: %{optional(atom) => any}
            ) :: {:ok, SearchResult.t()} | {:error, RubberBand.error()}

  @callback put_records(index_key :: Index.key(), data :: [any]) ::
              :ok | {:error, RubberBand.error()}

  @callback delete_doc(index_key :: Index.key(), id :: term) ::
              :ok | {:error, RubberBand.error()}

  @callback delete_docs_by_query(
              index_key :: Index.key(),
              search_opts :: %{optional(atom) => any}
            ) :: :ok | {:error, RubberBand.error()}

  defmacro __using__(opts \\ []) do
    quote do
      @behaviour unquote(__MODULE__)

      @spec __config__() :: Keyword.t()
      def __config__ do
        unquote(opts[:otp_app])
        |> Application.get_env(__MODULE__, [])
        |> Config.new()
      end

      @impl true
      def index_exists?(index_key) do
        unquote(__MODULE__).index_exists?(__config__(), index_key)
      end

      @impl true
      def create_index(index_key) do
        unquote(__MODULE__).create_index(__config__(), index_key)
      end

      @impl true
      def drop_index(index_key) do
        unquote(__MODULE__).drop_index(__config__(), index_key)
      end

      @impl true
      def doc_exists?(index_key, id) do
        unquote(__MODULE__).doc_exists?(__config__(), index_key, id)
      end

      defoverridable unquote(__MODULE__)
    end
  end

  @spec index_exists?(Config.t(), Index.key()) :: boolean
  def index_exists?(%Config{} = config, index_key) do
    delegate_to_adapter(config, index_key, :index_exists?)
  end

  @spec create_index(Config.t(), Index.key()) ::
          :ok | {:error, RubberBand.error()}
  def create_index(%Config{} = config, index_key) do
    delegate_to_adapter(config, index_key, :create_index)
  end

  @spec drop_index(Config.t(), Index.key()) ::
          :ok | {:error, RubberBand.error()}
  def drop_index(%Config{} = config, index_key) do
    delegate_to_adapter(config, index_key, :drop_index)
  end

  defp delegate_to_adapter(config, index_key, fun_name, args \\ []) do
    context = AdapterContext.new(config, index_key)
    apply(config.adapter, fun_name, [context | args])
  end
end
