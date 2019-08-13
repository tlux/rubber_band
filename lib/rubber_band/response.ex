defmodule RubberBand.Response do
  @moduledoc """
  The response to an Elasticsearch request.
  """

  @type t :: %__MODULE__{
          status_code: term,
          body: %{optional(atom) => any}
        }

  defstruct [:status_code, :body]

  @doc """
  Gets the hits from the response.
  """
  @spec hits(t) :: [map]
  def hits(%__MODULE__{} = response) do
    response.body
    |> get_in([:hits, :hits])
    |> List.wrap()
  end
end
