defmodule RubberBand.Adapters.V5 do
  @behaviour RubberBand.Adapter

  alias RubberBand.Client

  @type_name "doc"

  @impl true
  def index_exists?(config, index) do
    case Client.head(config.client, [index]) do
      {:ok, %{status_code: 200}} -> true
      _ -> false
    end
  end

  @impl true
  def create_index(config, index, callback_fun) do
    # TODO
  end

  @impl true
  def drop_index(config, index) do
    with {:ok, _} <- Client.delete(config.client, index) do
      :ok
    end
  end

  @impl true
  def doc_exists?(config, index, doc_id) do
    case Client.head(config.client, [index, @type_name, doc_id]) do
      {:ok, %{status_code: 200}} -> true
      _ -> false
    end
  end

  @impl true
  def get_doc(config, index, doc_id) do
    # TODO
  end

  @impl true
  def put_docs(config, index, docs) do
    # TODO
  end

  @impl true
  def search(config, index, opts) do
    Client.post(config.client, [index, @type_name, "_search"], opts)
  end
end
