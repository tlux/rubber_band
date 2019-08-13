defmodule RubberBand.SearchResult do
  @moduledoc """
  A module that provides helpers to easily access data from search result
  response bodies.
  """

  alias RubberBand.Config
  alias RubberBand.Doc
  alias RubberBand.Hit
  alias RubberBand.Index
  alias RubberBand.Response

  defstruct [:resp, :index_mod]

  @type t :: %__MODULE__{resp: Response.t(), index_mod: Index.mod()}

  @doc """
  Gets the number of hits.
  """
  @spec total_hits(t) :: non_neg_integer
  def total_hits(%__MODULE__{} = result) do
    result
    |> get_body()
    |> get_in([:hits, :total]) || 0
  end

  @doc """
  Gets the hits.
  """
  @spec hits(t) :: [Hit.t()]
  def hits(%__MODULE__{} = result) do
    result
    |> stream_hits()
    |> Enum.to_list()
  end

  @doc """
  Gets the hit sources.
  """
  @spec hit_sources(t) :: [Doc.t()]
  def hit_sources(%__MODULE__{} = result) do
    result
    |> stream_hits()
    |> Stream.map(& &1.doc)
    |> Enum.to_list()
  end

  @doc """
  Gets a stream containing the hits from the search result.
  """
  @spec stream_hits(t) :: Enum.t()
  def stream_hits(%__MODULE__{} = result) do
    result.resp
    |> Response.hits()
    |> Stream.map(&Doc.load(&1, result.index_mod))
  end

  @doc """
  Gets the aggregations from the result.
  """
  @spec aggregations(t) :: map
  def aggregations(%__MODULE__{} = result) do
    result
    |> get_body()
    |> Map.get(:aggregations, %{})
  end

  @doc """
  Gets a single aggregation identified by `key`.
  """
  @spec get_aggregation(t, atom) :: nil | map
  def get_aggregation(%__MODULE__{} = result, key) do
    result
    |> get_body()
    |> get_in([:aggregations, key])
  end

  @doc """
  Gets the suggestions from the result.
  """
  @spec suggestions(t) :: map
  def suggestions(%__MODULE__{} = result) do
    result
    |> get_body()
    |> Map.get(:suggest, %{})
  end

  defp get_body(result), do: result.resp.body
end
