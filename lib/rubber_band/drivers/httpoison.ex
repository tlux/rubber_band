defmodule RubberBand.Drivers.HTTPoison do
  @moduledoc """
  An adapter implementation that uses HTTPoison to dispatch requests to
  Elasticsearch.
  """

  @behaviour RubberBand.Driver

  @impl true
  def request(verb, url, body, headers, opts) do
    {:ok, _} = Application.ensure_all_started(:httpoison)

    case HTTPoison.request(verb, URI.to_string(url), body, headers, opts) do
      {:ok, resp} -> {:ok, Map.take(resp, [:body, :headers, :status_code])}
      {:error, error} -> {:error, %{reason: error.reason}}
    end
  end
end
