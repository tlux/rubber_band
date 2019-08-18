defmodule RubberBand.Adapters.V5 do
  @behaviour RubberBand.Adapter

  alias RubberBand.Client

  @type_name "doc"

  @impl true
  def index_exists?(config, index_name) do
    case Client.head(config, index_name) do
      {:ok, %{status_code: 200}} -> true
      _ -> false
    end
  end

  @impl true
  def drop_index(config, index_name_or_alias) do
    with {:ok, _} <- Client.delete(config, index_name_or_alias) do
      :ok
    end
  end

  @impl true
  def doc_exists?(config, index_name_or_alias, doc_id) do
    case Client.head(config, [index_name_or_alias, @type_name, doc_id]) do
      {:ok, %{status_code: 200}} -> true
      _ -> false
    end
  end
end
