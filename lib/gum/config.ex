defmodule Gum.Config do
  alias Gum.Store
  alias Gum.UnknownIndexError

  defstruct api: Gum.API.HTTP,
            client: %ESClient.Config{},
            index_prefix: nil,
            indices: %{},
            wait_for_refresh: true,
            type_name: nil

  @type t :: %__MODULE__{
          api: module,
          client: ESClient.Config.t(),
          index_prefix: nil | String.t(),
          indices: %{optional(atom) => Store.store_mod()},
          wait_for_refresh: boolean,
          type_name: nil | String.t()
        }

  @doc """
  Builds a new config.
  """
  @spec new(t | Keyword.t() | %{optional(atom) => any}) :: t
  def new(config_or_opts)
  def new(%__MODULE__{} = config), do: config
  def new(opts), do: struct(__MODULE__, opts)

  @doc """
  Gets the index name and store module from the configuration.
  """
  @spec fetch_index(t, Gum.index_key()) ::
          {:ok, String.t(), Store.store_mod()} | {:error, UnknownIndexError.t()}
  def fetch_index(%__MODULE__{} = config, index) do
    case Map.fetch(config.indices, index) do
      {:ok, store_mod} ->
        index_name = prefix_index_name(index, config.index_prefix)
        {:ok, index_name, store_mod}

      :error ->
        {:error, %UnknownIndexError{index: index}}
    end
  end

  defp prefix_index_name(index, nil), do: to_string(index)
  defp prefix_index_name(index, prefix), do: "#{prefix}#{index}"
end
