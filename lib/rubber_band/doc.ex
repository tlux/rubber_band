defmodule RubberBand.Doc do
  alias RubberBand.Index

  defstruct [:id, :source]

  @type source :: %{optional(atom) => any}
  @type t :: %__MODULE__{id: term, source: source}

  @spec load(%{optional(atom) => any}, Index.mod()) :: t
  def load(original, index_mod) do
    %__MODULE__{
      id: original[:_id],
      source: load_source(original[:_source], index_mod)
    }
  end

  defp load_source(nil, _index_mod), do: nil
  defp load_source(source, index_mod), do: index_mod.load(source)
end
