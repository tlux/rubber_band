defmodule RubberBand.Clients.HTTPoison do
  @moduledoc """
  An adapter implementation that uses HTTPoison to do HTTP requests to
  Elasticsearch.
  """

  @behaviour RubberBand.Client

  @impl true
  def request(verb, url, body, headers, opts) do
    {:ok, _} = Application.ensure_all_started(:httpoison)
    HTTPoison.request(verb, url, body, headers, opts)
  end
end
