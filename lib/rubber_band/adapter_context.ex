defmodule RubberBand.AdapterContext do
  @moduledoc """
  A context that is passed as first argument to an adapter.
  """

  alias RubberBand.Config
  alias RubberBand.Index

  defstruct [:config, :index_key, :index_mod, :index_name]

  @type t :: %__MODULE__{
          config: Config.t(),
          index_key: Index.key(),
          index_mod: Index.mod(),
          index_name: String.t()
        }

  @doc """
  Builds a new adapter context.
  """
  @spec new(Config.t(), Index.key()) :: t | no_return
  def new(config, index_key) do
    index_mod = Config.fetch_index_mod!(config, index_key)

    %__MODULE__{
      config: config,
      index_key: index_key,
      index_mod: index_mod,
      index_name: Config.get_index_name(config, index_key)
    }
  end
end
