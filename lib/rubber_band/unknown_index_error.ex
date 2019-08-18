defmodule RubberBand.UnknownIndexError do
  alias RubberBand.Index

  defstruct [:index]

  @type t :: %__MODULE__{index: Index.index_key()}
end
