defmodule RubberBand.Client.RequestError do
  @moduledoc """
  An error that is returned or raised when the search API returned an error.
  """

  defexception [:reason]

  @type t :: %__MODULE__{reason: any}

  @impl true
  def message(%__MODULE__{} = error) do
    "Request error: #{error.reason}"
  end
end
