defmodule RubberBand.Config do
  @moduledoc """
  A helper module to retrieve configuration values and defaults for the search
  engine.
  """

  alias RubberBand.Index
  alias RubberBand.UnknownIndexError

  defstruct adapter: RubberBand.Adapters.V5,
            client: RubberBand.Clients.HTTPoison,
            endpoint: nil,
            index_prefix: nil,
            indices: %{},
            json_library: Jason

  @type t :: %__MODULE__{
          adapter: module,
          client: module,
          endpoint: URI.t(),
          index_prefix: nil | String.t(),
          indices: %{optional(atom) => module}
        }

  @doc """
  Builds a new config.
  """
  @spec new(t | Keyword.t() | %{optional(atom) => any}) :: t
  def new(config_or_opts)
  def new(%__MODULE__{} = config), do: config
  def new(opts), do: struct(__MODULE__, opts)

  @doc """
  Gets the index with the given key from the config.
  """
  @spec fetch_index_mod(t, Index.key()) ::
          {:ok, Index.mod()} | {:error, UnknownIndexError.t()}
  def fetch_index_mod(%__MODULE__{} = config, key) do
    case Map.fetch(config, key) do
      {:ok, index_mod} -> {:ok, index_mod}
      :error -> {:error, %UnknownIndexError{key: key}}
    end
  end

  @doc """
  Gets the index with the given key from the config. Raises when the index could
  not be found among the registered ones.
  """
  @spec fetch_index_mod!(t, Index.key()) :: Index.mod() | no_return
  def fetch_index_mod!(%__MODULE__{} = config, key) do
    case fetch_index_mod(config, key) do
      {:ok, index_mod} -> index_mod
      {:error, error} -> raise error
    end
  end

  @doc """
  Gets the index name, applying the configured index prefix.
  """
  @spec get_index_name(t, Index.key()) :: String.t()
  def get_index_name(config, key)

  def get_index_name(%__MODULE__{index_prefix: nil}, key), do: to_string(key)

  def get_index_name(%__MODULE__{} = config, key) do
    "#{config.index_prefix}#{key}"
  end
end
