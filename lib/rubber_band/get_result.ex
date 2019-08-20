defmodule RubberBand.GetResult do
  alias RubberBand.Doc

  defstruct [:doc, :version]

  @type t :: %__MODULE__{doc: Doc.t(), version: non_neg_integer}
end
