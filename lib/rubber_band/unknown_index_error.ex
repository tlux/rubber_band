defmodule RubberBand.UnknownIndexError do
  defexception [:key]

  @type t :: %__MODULE__{key: atom}

  @impl true
  def message(%__MODULE__{} = error) do
    "Unknown index: #{error.key}"
  end
end
