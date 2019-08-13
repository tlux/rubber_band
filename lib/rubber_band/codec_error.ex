defmodule RubberBand.CodecError do
  @type t :: %__MODULE__{
          data: any,
          operation: :decode | :encode,
          original_error: nil | any
        }

  defexception [:operation, :data, :original_error]

  @impl true
  def message(error) do
    "Unable to #{error.operation} data"
  end
end
