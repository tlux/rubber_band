defmodule RubberBand.ResponseError do
  @moduledoc """
  An error that is returned or raised when the search API returned an error.
  """

  @type t :: %__MODULE__{
          col: nil | non_neg_integer,
          data: nil | %{optional(atom) => any},
          line: nil | non_neg_integer,
          reason: any,
          status_code: term,
          type: nil | String.t()
        }

  defexception [:data, :col, :line, :reason, :status_code, :type]

  @impl true
  def message(%__MODULE__{} = error) do
    "Response error: #{error.reason} (#{error.type})"
  end
end
