defmodule RubberBand.Client do
  @moduledoc """
  A low-level client that provides functions to retrieve and manage data from
  Elasticsearch.

  ## Usage

  You can either call the client directly if you have a config object.

      iex> cfg = %RubberBand.Client.Config{base_url: "http://localhost:9201"}
      ...> RubberBand.Client.get!(cfg, "_cat/health")
      #RubberBand.Client.Response<...>

  Or you can `use` this module to build your own custom client and obtain values
  from the application config.

      defmodule MyCustomClient
        use RubberBand.Client, otp_app: :my_app
      end

  Don't forget to add the configuration to your config.exs.

      use Mix.Config

      config :my_app, MyCustomClient, base_url: "http://localhost:9201"

  Then, use your client.

      iex> MyCustomClient.get!("_cat/health")
      #RubberBand.Client.Response<...>
  """

  alias __MODULE__
  alias RubberBand.Client.Codec
  alias RubberBand.Client.CodecError
  alias RubberBand.Client.Config
  alias RubberBand.Client.RequestError
  alias RubberBand.Client.Response
  alias RubberBand.Client.ResponseError
  alias RubberBand.Client.Utils

  @typedoc """
  A type that refers to a HTTP method to perform the request with.
  """
  @type verb :: :head | :get | :post | :put | :delete

  @typedoc """
  A type that defines a String containing path segments separated by slashes.
  """
  @type path_str :: String.t()

  @typedoc """
  A type that defines a list of path segments.
  """
  @type path_segments :: [String.t()]

  @typedoc """
  A type that defines a String containing path segments separated by slashes or
  a list of path segments.
  """
  @type path :: path_str | path_segments

  @typedoc """
  A type that defines request data.
  """
  @type req_data ::
          String.t() | Keyword.t() | %{optional(atom | String.t()) => any}

  @typedoc """
  Type defining an error that be be returned or raised when sending a request to
  a resource.
  """
  @type error :: CodecError.t() | RequestError.t() | ResponseError.t()

  @doc """
  Dispatch a request to the path at the configured endpoint using the specified
  request method.
  """
  @callback request(verb, path) :: {:ok, Response.t()} | {:error, error}

  @doc """
  Dispatch a request to the path at the configured endpoint using the specified
  request method and data.
  """
  @callback request(verb, path, req_data) ::
              {:ok, Response.t()} | {:error, error}

  @doc """
  Dispatch a request to the path at the configured endpoint using the specified
  request method. Raises when the request fails.
  """
  @callback request!(verb, path) :: Response.t() | no_return

  @doc """
  Dispatch a request to the path at the configured endpoint using the specified
  request method and data. Raises when the request fails.
  """
  @callback request!(verb, path, req_data) :: Response.t() | no_return

  @doc """
  Dispatch a HEAD request to the path at the configured endpoint.
  """
  @callback head(path) :: {:ok, Response.t()} | {:error, error}

  @doc """
  Dispatch a HEAD request to the path at the configured endpoint. Raises when
  the request fails.
  """
  @callback head!(path) :: Response.t() | no_return

  @doc """
  Dispatch a GET request to the path at the configured endpoint.
  """
  @callback get(path) :: {:ok, Response.t()} | {:error, error}

  @doc """
  Dispatch a GET request to the path at the configured endpoint. Raises when
  the request fails.
  """
  @callback get!(path) :: Response.t() | no_return

  @doc """
  Dispatch a POST request to the path at the configured endpoint.
  """
  @callback post(path) :: {:ok, Response.t()} | {:error, error}

  @doc """
  Dispatch a POST request to the path at the configured endpoint using the
  specified request data.
  """
  @callback post(path, req_data) :: {:ok, Response.t()} | {:error, error}

  @doc """
  Dispatch a POST request to the path at the configured endpoint. Raises when
  the request fails.
  """
  @callback post!(path) :: Response.t() | no_return

  @doc """
  Dispatch a POST request to the path at the configured endpoint using the
  specified request data. Raises when the request fails.
  """
  @callback post!(path, req_data) :: Response.t() | no_return

  @doc """
  Dispatch a PUT request to the path at the configured endpoint.
  """
  @callback put(path) :: {:ok, Response.t()} | {:error, error}

  @doc """
  Dispatch a PUT request to the path at the configured endpoint using the
  specified request data.
  """
  @callback put(path, req_data) :: {:ok, Response.t()} | {:error, error}

  @doc """
  Dispatch a PUT request to the path at the configured endpoint. Raises when
  the request fails.
  """
  @callback put!(path) :: Response.t() | no_return

  @doc """
  Dispatch a PUT request to the path at the configured endpoint using the
  specified request data. Raises when the request fails.
  """
  @callback put!(path, req_data) :: Response.t() | no_return

  @doc """
  Dispatch a DELETE request to the path at the configured endpoint.
  """
  @callback delete(path) :: {:ok, Response.t()} | {:error, error}

  @doc """
  Dispatch a DELETE request to the path at the configured endpoint. Raises when
  the request fails.
  """
  @callback delete!(path) :: Response.t() | no_return

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)

    quote do
      @behaviour Client

      @doc false
      @spec __config__() :: Config.t()
      def __config__ do
        unquote(otp_app)
        |> Application.get_env(__MODULE__, [])
        |> Config.new()
      end

      @impl true
      def request(verb, path, req_data \\ nil) do
        Client.request(__config__(), verb, path, req_data)
      end

      @impl true
      def request!(verb, path, req_data \\ nil) do
        Client.request!(__config__(), verb, path, req_data)
      end

      @impl true
      def head(path) do
        Client.head(__config__(), path)
      end

      @impl true
      def head!(path) do
        Client.head!(__config__(), path)
      end

      @impl true
      def get(path) do
        Client.get(__config__(), path)
      end

      @impl true
      def get!(path) do
        Client.get!(__config__(), path)
      end

      @impl true
      def post(path, req_data \\ nil) do
        Client.post(__config__(), path, req_data)
      end

      @impl true
      def post!(path, req_data \\ nil) do
        Client.post!(__config__(), path, req_data)
      end

      @impl true
      def put(path, req_data \\ nil) do
        Client.put(__config__(), path, req_data)
      end

      @impl true
      def put!(path, req_data \\ nil) do
        Client.put!(__config__(), path, req_data)
      end

      @impl true
      def delete(path) do
        Client.delete(__config__(), path)
      end

      @impl true
      def delete!(path) do
        Client.delete!(__config__(), path)
      end

      defoverridable Client
    end
  end

  @doc """
  Sends a request with the given verb to the configured endpoint.
  """
  @spec request(config :: Config.t(), verb, path, nil | req_data) ::
          {:ok, Response.t()} | {:error, error}
  def request(%Config{} = config, verb, path, req_data \\ nil) do
    with {:ok, req_data} <- Codec.encode(config, req_data),
         {:ok, resp} <- do_request(config, verb, path, req_data),
         content_type = get_content_type(resp.headers),
         {:ok, resp_data} <- Codec.decode(config, content_type, resp.body) do
      build_resp(resp.status_code, content_type, resp_data)
    end
  end

  defp do_request(config, verb, path, req_data) do
    url = Utils.build_url(config, path)
    opts = [recv_timeout: config.timeout]

    case config.driver.request(verb, url, req_data, [], opts) do
      {:ok, resp} ->
        {:ok, resp}

      {:error, %{reason: reason}} ->
        {:error, %RequestError{reason: reason}}
    end
  end

  defp get_content_type(headers) do
    Enum.find_value(headers, fn
      {"content-type", content_type} ->
        content_type
        |> String.split(";")
        |> List.first()

      _ ->
        nil
    end)
  end

  defp build_resp(status_code, _content_type, %{error: error} = data) do
    attrs =
      error
      |> Map.take([:col, :line, :reason, :type])
      |> Map.put(:data, data)
      |> Map.put(:status_code, status_code)

    {:error, struct!(ResponseError, attrs)}
  end

  defp build_resp(status_code, content_type, data) do
    {:ok,
     %Response{content_type: content_type, data: data, status_code: status_code}}
  end

  @doc """
  Dispatch a request to the path at the configured endpoint using the specified
  request method and data. Raises when the request fails.
  """
  @spec request!(Config.t(), verb, path, nil | req_data) ::
          Response.t() | no_return
  def request!(%Config{} = config, verb, path, req_data \\ nil) do
    case request(config, verb, path, req_data) do
      {:ok, resp} -> resp
      {:error, error} -> raise error
    end
  end

  @doc """
  Dispatch a HEAD request to the path at the configured endpoint.
  """
  @spec head(Config.t(), path) :: {:ok, Response.t()} | {:error, error}
  def head(%Config{} = config, path), do: request(config, :head, path)

  @doc """
  Dispatch a HEAD request to the path at the configured endpoint. Raises when
  the request fails.
  """
  @spec head!(Config.t(), path) :: Response.t() | no_return
  def head!(%Config{} = config, path), do: request!(config, :head, path)

  @doc """
  Dispatch a GET request to the path at the configured endpoint.
  """
  @spec get(Config.t(), path) ::
          {:ok, Response.t()} | {:error, error}
  def get(%Config{} = config, path), do: request(config, :get, path)

  @doc """
  Dispatch a GET request to the path at the configured endpoint. Raises when
  the request fails.
  """
  @spec get!(Config.t(), path) :: Response.t() | no_return
  def get!(%Config{} = config, path), do: request!(config, :get, path)

  @doc """
  Dispatch a POST request to the path at the configured endpoint using the
  specified request data.
  """
  @spec post(Config.t(), path, nil | req_data) ::
          {:ok, Response.t()} | {:error, error}
  def post(%Config{} = config, path, req_data \\ nil) do
    request(config, :post, path, req_data)
  end

  @doc """
  Dispatch a POST request to the path at the configured endpoint using the
  specified request data. Raises when the request fails.
  """
  @spec post!(Config.t(), path, nil | req_data) ::
          Response.t() | no_return
  def post!(%Config{} = config, path, req_data \\ nil) do
    request!(config, :post, path, req_data)
  end

  @doc """
  Dispatch a PUT request to the path at the configured endpoint using the
  specified request data.
  """
  @spec put(Config.t(), path, nil | req_data) ::
          {:ok, Response.t()} | {:error, error}
  def put(%Config{} = config, path, req_data \\ nil) do
    request(config, :put, path, req_data)
  end

  @doc """
  Dispatch a PUT request to the path at the configured endpoint using the
  specified request data. Raises when the request fails.
  """
  @spec put!(Config.t(), path, nil | req_data) ::
          Response.t() | no_return
  def put!(%Config{} = config, path, req_data \\ nil) do
    request!(config, :put, path, req_data)
  end

  @doc """
  Dispatch a GET request to the path at the configured endpoint.
  """
  @spec delete(Config.t(), path) ::
          {:ok, Response.t()} | {:error, error}
  def delete(%Config{} = config, path) do
    request(config, :delete, path)
  end

  @doc """
  Dispatch a GET request to the path at the configured endpoint. Raises when
  the request fails.
  """
  @spec delete!(Config.t(), path) :: Response.t() | no_return
  def delete!(%Config{} = config, path) do
    request!(config, :delete, path)
  end
end
