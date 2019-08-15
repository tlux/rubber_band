defmodule RubberBand.Client do
  @moduledoc """
  A low-level client that provides functions to retrieve and manage data from
  Elasticsearch.
  """

  alias __MODULE__
  alias RubberBand.CodecError
  alias RubberBand.Config
  alias RubberBand.Driver
  alias RubberBand.RequestError
  alias RubberBand.Response
  alias RubberBand.ResponseError

  import RubberBand.Codec
  import RubberBand.URLBuilder
  
  @type path :: String.t() | [String.t()]

  @type req_data ::
          String.t() | Keyword.t() | %{optional(atom | String.t()) => any}

  @type error :: CodecError.t() | RequestError.t() | ResponseError.t()

  @callback request(verb :: Driver.verb(), path) :: {:ok, Response.t()} | {:error, error}

  @callback request(verb :: Driver.verb(), path, req_data) :: {:ok, Response.t()} | {:error, error}

  @callback request!(verb :: Driver.verb(), path) :: Response.t() | no_return

  @callback request!(verb :: Driver.verb(), path, req_data) :: Response.t() | no_return

  @callback head(path) :: {:ok, Response.t()} | {:error, error}

  @callback head!(path) :: Response.t() | no_return

  @callback get(path) :: {:ok, Response.t()} | {:error, error}

  @callback get!(path) :: Response.t() | no_return

  @callback post(path) :: {:ok, Response.t()} | {:error, error}

  @callback post(path, req_data) :: {:ok, Response.t()} | {:error, error}

  @callback post!(path) :: Response.t() | no_return

  @callback post!(path, req_data) :: Response.t() | no_return

  @callback put(path) :: {:ok, Response.t()} | {:error, error}

  @callback put(path, req_data) :: {:ok, Response.t()} | {:error, error}

  @callback put!(path) :: Response.t() | no_return

  @callback put!(path, req_data) :: Response.t() | no_return

  @callback delete(path) :: {:ok, Response.t()} | {:error, error}

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
      def request(verb, path, req_data \\ %{}) do
        Client.request(__config__(), verb, path, req_path)
      end

      @impl true
      def request!(verb, path, req_data \\ %{}) do
        Client.request!(__config__(), verb, path, req_path)
      end
      
      Enum.each([:head, :head!, :get, :get!, :delete, :delete!], fn fun ->
        @impl true
        def unquote(fun)(path) do
          Client.unquote(fun)(__config__(), path)
        end
      end)
      
      Enum.each([:post, :post!, :put, :put!], fn fun ->
        @impl true
        def unquote(fun)(path, req_data \\ %{}) do
          Client.unquote(fun)(__config__(), path, req_data)
        end
      end)

      defoverridable Client
    end
  end

  @doc """
  Sends a request with the given verb to the configured endpoint.
  """
  @spec request(
          config :: Config.t(),
          verb :: Driver.verb(),
          path :: String.t(),
          req_data
        ) :: {:ok, Response.t()} | {:error, error}
  def request(%Config{} = config, verb, path, req_data \\ %{}) do
    with {:ok, req_data} <- encode(config, req_data),
         {:ok, resp} <- do_request(config, verb, path, req_data),
         content_type = get_content_type(resp.headers),
         {:ok, resp_data} <- decode(config, content_type, resp.body) do
      build_resp(resp.status_code, content_type, resp_data)
    end
  end

  @doc """
  Sends a request with the given verb to the configured endpoint. Raises when an
  error occurs.
  """
  @spec request!(
          config :: Config.t(),
          verb :: Driver.verb(),
          path :: String.t(),
          req_data
        ) :: Response.t() | no_return
  def request!(%Config{} = config, verb, path, req_data \\ %{}) do
    case request(config, verb, path, req_data) do
      {:ok, resp} -> resp
      {:error, error} -> raise error
    end
  end

  defp do_request(config, verb, path, req_data) do
    url = build_url(config, path)
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

  @doc """
  Sends a `HEAD` request to the configured endpoint.
  """
  @spec head(config :: Config.t(), path) :: {:ok, Response.t()} | {:error, error}
  def head(%Config{} = config, path), do: request(config, :head, path)

  @doc """
  Sends a `HEAD` request to the configured endpoint. Raises when an error
  occurs.
  """
  @spec head!(config :: Config.t(), path) :: Response.t() | no_return
  def head!(%Config{} = config, path), do: request!(config, :head, path)

  @doc """
  Sends a `GET` request to the configured endpoint.
  """
  @spec get(config :: Config.t(), path) :: {:ok, Response.t()} | {:error, error}
  def get(%Config{} = config, path), do: request(config, :get, path)

  @doc """
  Sends a `GET` request to the configured endpoint. Raises when an error occurs.
  """
  @spec get!(config :: Config.t(), path) :: Response.t() | no_return
  def get!(%Config{} = config, path), do: request!(config, :get, path)

  @doc """
  Sends a `POST` request to the configured endpoint.
  """
  @spec post(config :: Config.t(), path, req_data) :: {:ok, Response.t()} | {:error, error}
  def post(%Config{} = config, path, req_data \\ %{}) do
    request(config, :post, path, req_data)
  end

  @doc """
  Sends a `POST` request to the configured endpoint. Raises when an error
  occurs.
  """
  @spec post!(config :: Config.t(), path, req_data) :: Response.t() | no_return
  def post!(%Config{} = config, path, req_data \\ %{}) do
    request!(config, :post, path, req_data)
  end

  @doc """
  Sends a `PUT` request to the configured endpoint.
  """
  @spec put(config :: Config.t(), path, req_data) :: {:ok, Response.t()} | {:error, error}
  def put(%Config{} = config, path, req_data \\ %{}) do
    request(config, :put, path, req_data)
  end

  @doc """
  Sends a `PUT` request to the configured endpoint. Raises when an error occurs.
  """
  @spec put!(config :: Config.t(), path, req_data) :: Response.t() | no_return
  def put!(%Config{} = config, path, req_data \\ %{}) do
    request!(config, :put, path, req_data)
  end

  @doc """
  Sends a `DELETE` request to the configured endpoint.
  """
  @spec delete(config :: Config.t(), path) :: {:ok, Response.t()} | {:error, error}
  def delete(%Config{} = config, path), do: request(config, :delete, path)

  @doc """
  Sends a `DELETE` request to the configured endpoint. Raises when an error
  occurs.
  """
  @spec delete!(config :: Config.t(), path) :: Response.t() | no_return
  def delete!(%Config{} = config, path), do: request!(config, :delete, path)

  defp build_resp(status_code, _content_type, %{error: error} = data) do
    attrs =
      error
      |> Map.take([:col, :line, :reason, :type])
      |> Map.put(:data, data)
      |> Map.put(:status_code, status_code)

    {:error, struct(ResponseError, attrs)}
  end

  defp build_resp(status_code, content_type, data) do
    {:ok,
     %Response{content_type: content_type, data: data, status_code: status_code}}
  end
end
