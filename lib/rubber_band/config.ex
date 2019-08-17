defmodule RubberBand.Config do
  alias RubberBand.Client.Config, as: ClientConfig

  defstruct adapter: RubberBand.Repo.Adapters.V5,
            client: %ClientConfig{},
            index_prefix: nil

  @type t :: %__MODULE__{
          adapter: module,
          client: RubberBand.Client.Config.t(),
          index_prefix: nil | String.t()
        }
end
