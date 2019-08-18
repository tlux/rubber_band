defmodule RubberBand.BulkOperation do
  alias RubberBand.Doc

  defstruct [:action, :id, :source]

  @type t :: %__MODULE__{
          action: :index | :delete | :create | :update,
          id: term,
          source: Doc.source()
        }
end
