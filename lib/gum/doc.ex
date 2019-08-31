defmodule Gum.Doc do
  defstruct [:id, :source]

  @type source :: %{optional(atom) => any}
  @type t :: %__MODULE__{id: term, source: source}
end
