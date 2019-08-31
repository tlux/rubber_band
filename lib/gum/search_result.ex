defmodule Gum.SearchResult do
  alias Gum.Hits

  defstruct [:hits, aggregations: %{}]

  @type t :: %__MODULE__{
          hits: Hits.t(),
          aggregations: %{optional(atom) => any}
        }
end
