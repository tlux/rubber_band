defmodule RubberBand.Hit do
  @moduledoc """
  A struct containing the ID and source data for a document.
  """

  alias RubberBand.Doc
  alias RubberBand.Index

  defstruct [:index_mod, :doc, inner_hits: %{}]

  @type t :: %__MODULE__{
          index_mod: Index.mod(),
          doc: Doc.t(),
          inner_hits: %{optional(atom) => t}
        }

  @doc """
  Loads the doc from a given map using the load/1 function from the specified
  store module.
  """
  @spec load(%{optional(atom) => any}, Index.mod()) :: t
  def load(original, index_mod) do
    %__MODULE__{
      index_mod: index_mod,
      doc: Doc.load(original, index_mod),
      inner_hits: original[:inner_hits] || %{}
    }
  end

  @doc """
  Gets the inner hits of the document.
  """
  @spec inner_hits(t, atom) :: [t]
  def inner_hits(%__MODULE__{} = doc, key) do
    doc
    |> stream_inner_hits(key)
    |> Enum.to_list()
  end

  @doc """
  Gets the sources from inner hits of the document.
  """
  @spec inner_hit_sources(t, atom) :: [Doc.t()]
  def inner_hit_sources(%__MODULE__{} = doc, key) do
    doc
    |> stream_inner_hits(key)
    |> Stream.map(& &1.source)
    |> Enum.to_list()
  end

  @doc """
  Gets a stream containing the inner hits.
  """
  @spec stream_inner_hits(t, atom) :: Enum.t()
  def stream_inner_hits(%__MODULE__{} = doc, key) do
    doc.inner_hits
    |> get_in([key, :hits, :hits])
    |> List.wrap()
    |> Stream.map(&load(&1, doc.index_mod))
  end
end
