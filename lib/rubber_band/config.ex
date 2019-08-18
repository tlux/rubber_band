defmodule RubberBand.Config do
  alias RubberBand.Client.Config, as: ClientConfig
  alias RubberBand.Index

  defstruct adapter: RubberBand.Repo.Adapters.V5,
            client: %ClientConfig{},
            index_prefix: nil,
            indices: %{}

  @type t :: %__MODULE__{
          adapter: module,
          client: RubberBand.Client.Config.t(),
          index_prefix: nil | String.t(),
          indices: %{optional(Index.index_key()) => Index.index_mod()}
        }
end
