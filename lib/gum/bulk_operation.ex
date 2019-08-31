defmodule Gum.BulkOperation do
  alias Gum.Doc

  defstruct [:action, :id, :source]

  @type t :: %__MODULE__{
          action: :index | :delete | :create | :update,
          id: term,
          source: Doc.source()
        }
end
