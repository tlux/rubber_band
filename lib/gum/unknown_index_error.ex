defmodule Gum.UnknownIndexError do
  alias Gum.Index

  defstruct [:index]

  @type t :: %__MODULE__{index: Gum.index_key()}
end
