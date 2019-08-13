defmodule RubberBand.Client do
  @moduledoc """
  A low-level adapter that allows plugging different HTTP adapters into the
  Elasticsearch API.
  """

  @type verb :: :head | :get | :post | :put | :delete
  @type resp :: HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()
  @type error :: HTTPoison.Error.t()

  @doc """
  A callback for implementing an own function to send a request to a HTTP
  endpoint.
  """
  @callback request(
              verb :: verb,
              url :: String.t() | URI.t(),
              body :: String.t(),
              headers :: HTTPoison.Request.headers(),
              opts :: Keyword.t()
            ) :: {:ok, resp} | {:error, error}

  @spec request(
          client :: module,
          verb :: atom,
          url :: String.t() | URI.t(),
          body :: String.t(),
          headers :: HTTPoison.Request.headers(),
          opts :: Keyword.t()
        ) :: {:ok, resp} | {:error, error}
  def request(client, verb, url, body \\ nil, headers \\ [], opts \\ []) do
    client.request(verb, url, body, headers, opts)
  end

  @spec head(
          client :: module,
          url :: String.t() | URI.t(),
          headers :: HTTPoison.Request.headers(),
          opts :: Keyword.t()
        ) :: {:ok, resp} | {:error, error}
  def head(client, url, headers \\ [], opts \\ []) do
    request(client, :head, url, nil, headers, opts)
  end

  @spec get(
          client :: module,
          url :: String.t() | URI.t(),
          headers :: HTTPoison.Request.headers(),
          opts :: Keyword.t()
        ) :: {:ok, resp} | {:error, error}
  def get(client, url, headers \\ [], opts \\ []) do
    request(client, :get, url, nil, headers, opts)
  end

  @spec post(
          client :: module,
          url :: String.t() | URI.t(),
          body :: String.t(),
          headers :: HTTPoison.Request.headers(),
          opts :: Keyword.t()
        ) :: {:ok, resp} | {:error, error}
  def post(client, url, body \\ nil, headers \\ [], opts \\ []) do
    request(client, :post, url, body, headers, opts)
  end

  @spec put(
          client :: module,
          url :: String.t() | URI.t(),
          body :: String.t(),
          headers :: HTTPoison.Request.headers(),
          opts :: Keyword.t()
        ) :: {:ok, resp} | {:error, error}
  def put(client, url, body \\ nil, headers \\ [], opts \\ []) do
    request(client, :put, url, body, headers, opts)
  end

  @spec delete(
          client :: module,
          url :: String.t() | URI.t(),
          headers :: HTTPoison.Request.headers(),
          opts :: Keyword.t()
        ) :: {:ok, resp} | {:error, error}
  def delete(client, url, headers \\ [], opts \\ []) do
    request(client, :delete, url, nil, headers, opts)
  end
end
