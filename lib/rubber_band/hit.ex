defmodule RubberBand.Hit do
  alias RubberBand.Doc

  defstruct [:doc, score: 0.0]

  @type t :: %__MODULE__{doc: Doc.t(), score: float}
end
