defmodule RubberBand.Driver do
  @type verb :: :head | :get | :post | :put | :delete

  @type req_headers ::
          Keyword.t(binary)
          | [{String.t(), binary}]
          | %{optional(atom | String.t()) => binary}

  @type resp_headers :: [{String.t(), binary}]

  @type resp :: %{
          status_code: term,
          headers: resp_headers,
          body: binary
        }

  @type error :: %{reason: any}

  @doc """
  A callback for implementing an own function to send a request to a HTTP
  endpoint.
  """
  @callback request(
              verb,
              url :: URI.t(),
              body :: binary,
              headers :: req_headers,
              opts :: Keyword.t()
            ) :: {:ok, resp} | {:error, error}
end
