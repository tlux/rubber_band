defmodule Gum.Store do
  alias __MODULE__
  alias Gum.Doc

  @type context :: %{optional(atom) => any}
  @type source :: any
  @type store_mod :: module

  @callback settings() :: %{optional(atom) => any}

  @callback mappings() :: %{optional(atom) => any}

  @callback sources() :: [source]

  @callback populate_stream(source) :: any

  @callback populate_transaction(source, callback :: (() -> result)) :: result
            when result: any

  @callback load_context() :: context

  @callback load_doc(Doc.t(), context) :: Doc.t()

  @callback dump_context() :: context

  @callback dump_data(source, data :: any, context) :: Doc.t() | [Doc.t()]

  @optional_callbacks [settings: 0, mappings: 0]

  defmacro __using__(_opts) do
    quote do
      @behaviour Store

      defoverridable Store
    end
  end
end
