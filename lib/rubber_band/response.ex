defmodule RubberBand.Response do
  @moduledoc """
  The response to an Elasticsearch request.
  """

  @type t :: %__MODULE__{
          data: %{optional(atom) => any},
          status_code: term
        }

  defstruct [:data, :status_code]

  @doc """
  Gets the hits from the response.
  """
  @spec hits(t) :: [map]
  def hits(%__MODULE__{} = response) do
    response.data
    |> get_in([:hits, :hits])
    |> List.wrap()
  end
end
