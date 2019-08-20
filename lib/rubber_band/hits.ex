defmodule RubberBand.Hits do
  alias RubberBand.Hit

  defstruct max_score: 0.0, total: 0, entries: []

  @type t :: %__MODULE__{
          max_score: float,
          total: non_neg_integer,
          entries: [Hit.t()]
        }
end
