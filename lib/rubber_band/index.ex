defmodule RubberBand.Index do
  alias RubberBand.Doc

  @type index_key :: atom
  @type index_mod :: module

  @callback settings() :: %{optional(atom) => any}

  @callback mapping() :: %{optional(atom) => any}

  @callback populate() :: any

  @callback load(Doc.t()) :: Doc.t()

  @callback dump(any) :: [Doc.t()]

  @callback doc_id(Doc.t()) :: term

  @optional_callbacks [settings: 0, mapping: 0]

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end
end
