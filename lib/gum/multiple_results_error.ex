defmodule Gum.MultipleResultsError do
  @moduledoc """
  An exception that is returned or raised when a find query returns more than
  one result.
  """

  defexception [:count]

  @type t :: %__MODULE__{count: non_neg_integer}

  def message(%__MODULE__{count: count}) do
    "Expected at most one result but got #{count}"
  end
end
