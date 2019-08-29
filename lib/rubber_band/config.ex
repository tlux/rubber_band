defmodule RubberBand.Config do
  alias RubberBand.Index

  defstruct adapter: RubberBand.Repo.Adapters.V5,
            client: %ESClient.Config{},
            index_prefix: nil,
            indices: %{},
            wait_for_refresh: true

  @type t :: %__MODULE__{
          adapter: module,
          client: ESClient.Config.t(),
          index_prefix: nil | String.t(),
          indices: %{optional(Index.index_key()) => Index.index_mod()},
          wait_for_refresh: boolean
        }
end
