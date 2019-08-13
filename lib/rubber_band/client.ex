defmodule RubberBand.Client do
  @moduledoc """
  A low-level client that provides functions to retrieve and manage data from
  Elasticsearch.
  """

  alias RubberBand.Client.CodecError
  alias RubberBand.Client.Config
  alias RubberBand.Driver
  alias RubberBand.RequestError
  alias RubberBand.Response
  alias RubberBand.ResponseError

  import RubberBand.Client.Codec
  import RubberBand.Client.URLBuilder

  @type req_data ::
          String.t() | Keyword.t() | %{optional(atom | String.t()) => any}

  @type error :: CodecError.t() | RequestError.t() | ResponseError.t()

  @callback request(verb :: Driver.verb(), path :: String.t()) ::
              {:ok, Response.t()} | {:error, error}

  @callback request(
              verb :: Driver.verb(),
              path :: String.t(),
              req_data
            ) :: {:ok, Response.t()} | {:error, error}

  @callback request!(verb :: Driver.verb(), path :: String.t()) ::
              Response.t() | no_return

  @callback request!(
              verb :: Driver.verb(),
              path :: String.t(),
              req_data
            ) :: Response.t() | no_return

  @callback head(path :: String.t()) ::
              {:ok, Response.t()} | {:error, error}

  @callback head!(path :: String.t()) :: Response.t() | no_return

  @callback get(path :: String.t()) :: {:ok, Response.t()} | {:error, error}

  @callback get!(path :: String.t()) :: Response.t() | no_return

  @callback post(path :: String.t()) ::
              {:ok, Response.t()} | {:error, error}

  @callback post(path :: String.t(), req_data) ::
              {:ok, Response.t()} | {:error, error}

  @callback post!(path :: String.t()) :: Response.t() | no_return

  @callback post!(path :: String.t(), req_data) :: Response.t() | no_return

  @callback put(path :: String.t()) :: {:ok, Response.t()} | {:error, error}

  @callback put(path :: String.t(), req_data) ::
              {:ok, Response.t()} | {:error, error}

  @callback put!(path :: String.t()) :: Response.t() | no_return

  @callback put!(path :: String.t(), req_data) :: Response.t() | no_return

  @callback delete(path :: String.t()) ::
              {:ok, Response.t()} | {:error, error}

  @callback delete!(path :: String.t()) :: Response.t() | no_return

  defmacro __using__(opts \\ []) do
    quote do
      @behaviour unquote(__MODULE__)

      @doc false
      @spec __config__() :: Config.t()
      def __config__ do
        unquote(opts[:otp_app])
        |> Application.get_env(unquote(__MODULE__), [])
        |> Config.new()
      end

      @impl true
      def request(verb, path, req_path \\ %{}) do
        unquote(__MODULE__).request(__config__(), verb, path, req_path)
      end

      @impl true
      def request!(verb, path, req_path \\ %{}) do
        unquote(__MODULE__).request!(__config__(), verb, path, req_path)
      end

      @impl true
      def head(path) do
        unquote(__MODULE__).head(__config__(), path)
      end

      @impl true
      def head!(path) do
        unquote(__MODULE__).head!(__config__(), path)
      end

      @impl true
      def get(path) do
        unquote(__MODULE__).get(__config__(), path)
      end

      @impl true
      def get!(path) do
        unquote(__MODULE__).get!(__config__(), path)
      end

      @impl true
      def post(path, req_path \\ %{}) do
        unquote(__MODULE__).post(__config__(), path, req_path)
      end

      @impl true
      def post!(path, req_path \\ %{}) do
        unquote(__MODULE__).post!(__config__(), path, req_path)
      end

      @impl true
      def put(path, req_path \\ %{}) do
        unquote(__MODULE__).put(__config__(), path, req_path)
      end

      @impl true
      def put!(path, req_path \\ %{}) do
        unquote(__MODULE__).put!(__config__(), path, req_path)
      end

      @impl true
      def delete(path) do
        unquote(__MODULE__).delete(__config__(), path)
      end

      @impl true
      def delete!(path) do
        unquote(__MODULE__).delete!(__config__(), path)
      end

      defoverridable unquote(__MODULE__)
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
         {:ok, resp_data} <- do_decode(config, resp) do
      build_resp(resp_data, resp.status_code)
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

      {:error, %{id: id, reason: reason}} ->
        {:error, %RequestError{id: id, reason: reason}}
    end
  end

  defp do_decode(config, resp) do
    content_type = get_content_type(resp.headers)
    decode(config, content_type, resp.body)
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
  @spec head(config :: Config.t(), path :: String.t()) ::
          {:ok, Response.t()} | {:error, error}
  def head(config, path), do: request(config, :head, path)

  @doc """
  Sends a `HEAD` request to the configured endpoint. Raises when an error
  occurs.
  """
  @spec head!(config :: Config.t(), path :: String.t()) ::
          Response.t() | no_return
  def head!(config, path), do: request!(config, :head, path)

  @doc """
  Sends a `GET` request to the configured endpoint.
  """
  @spec get(config :: Config.t(), path :: String.t()) ::
          {:ok, Response.t()} | {:error, error}
  def get(config, path), do: request(config, :get, path)

  @doc """
  Sends a `GET` request to the configured endpoint. Raises when an error occurs.
  """
  @spec get!(config :: Config.t(), path :: String.t()) ::
          Response.t() | no_return
  def get!(config, path), do: request!(config, :get, path)

  @doc """
  Sends a `POST` request to the configured endpoint.
  """
  @spec post(config :: Config.t(), path :: String.t(), req_data) ::
          {:ok, Response.t()} | {:error, error}
  def post(config, path, req_data \\ %{}) do
    request(config, :post, path, req_data)
  end

  @doc """
  Sends a `POST` request to the configured endpoint. Raises when an error
  occurs.
  """
  @spec post!(config :: Config.t(), path :: String.t(), req_data) ::
          Response.t() | no_return
  def post!(config, path, req_data \\ %{}) do
    request!(config, :post, path, req_data)
  end

  @doc """
  Sends a `PUT` request to the configured endpoint.
  """
  @spec put(config :: Config.t(), path :: String.t(), req_data) ::
          {:ok, Response.t()} | {:error, error}
  def put(config, path, req_data \\ %{}) do
    request(config, :put, path, req_data)
  end

  @doc """
  Sends a `PUT` request to the configured endpoint. Raises when an error occurs.
  """
  @spec put!(config :: Config.t(), path :: String.t(), req_data) ::
          Response.t() | no_return
  def put!(config, path, req_data \\ %{}) do
    request!(config, :put, path, req_data)
  end

  @doc """
  Sends a `DELETE` request to the configured endpoint.
  """
  @spec delete(config :: Config.t(), path :: String.t()) ::
          {:ok, Response.t()} | {:error, error}
  def delete(config, path), do: request(config, :delete, path)

  @doc """
  Sends a `DELETE` request to the configured endpoint. Raises when an error
  occurs.
  """
  @spec delete!(config :: Config.t(), path :: String.t()) ::
          Response.t() | no_return
  def delete!(config, path), do: request!(config, :delete, path)

  defp build_resp(%{error: error} = data, status_code) do
    attrs =
      error
      |> Map.take([:col, :line, :reason, :type])
      |> Map.put(:data, data)
      |> Map.put(:status_code, status_code)

    {:error, struct(ResponseError, attrs)}
  end

  defp build_resp(data, status_code) do
    {:ok, %Response{data: data, status_code: status_code}}
  end
end
