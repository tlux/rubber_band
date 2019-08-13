defmodule RubberBand.ResponseError do
  @moduledoc """
  An error that is returned or raised when the search API returned an error.
  """

  @type t :: %__MODULE__{
          body: %{optional(atom) => any},
          type: String.t(),
          reason: String.t(),
          line: nil | non_neg_integer,
          col: nil | non_neg_integer,
          status_code: term
        }

  defexception [:body, :type, :reason, :line, :col, :status_code]

  @impl true
  def message(%__MODULE__{} = error) do
    "Search error: #{error.type} (#{error.reason})"
  end
end
