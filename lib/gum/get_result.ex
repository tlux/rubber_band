defmodule Gum.GetResult do
  alias Gum.Doc

  defstruct [:doc, :version]

  @type t :: %__MODULE__{doc: Doc.t(), version: non_neg_integer}
end
