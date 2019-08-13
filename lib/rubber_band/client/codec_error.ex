defmodule RubberBand.Client.CodecError do
  @type t :: %__MODULE__{
          operation: :decode | :encode,
          data: any,
          original_error: nil | any
        }

  defexception [:operation, :data, :original_error]

  @impl true
  def message(error) do
    "Unable to #{error.operation} data"
  end
end
