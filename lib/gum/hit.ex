defmodule Gum.Hit do
  alias Gum.Doc

  defstruct [:doc, score: 0.0]

  @type t :: %__MODULE__{doc: Doc.t(), score: float}
end
