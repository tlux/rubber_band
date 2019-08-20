defmodule RubberBand.SearchResult do
  alias RubberBand.Hits

  defstruct [:hits, aggregations: %{}]

  @type t :: %__MODULE__{
          hits: Hits.t(),
          aggregations: %{optional(atom) => any}
        }
end
