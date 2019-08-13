defmodule RubberBand.Client.Codec do
  alias RubberBand.Client.CodecError
  alias RubberBand.Config

  @doc """
  Decodes data using the JSON codec from the given config.
  """
  @spec decode(Config.t(), String.t(), any) ::
          {:ok, any} | {:error, CodecError.t()}
  def decode(config, content_type, data)

  def decode(_config, _content_type, nil), do: {:ok, nil}

  def decode(_config, _content_type, ""), do: {:ok, nil}

  def decode(config, "application/json", data) when is_binary(data) do
    with {:error, error} <- config.json_codec.decode(data, keys: :atoms) do
      {:error,
       %CodecError{operation: :decode, data: data, original_error: error}}
    end
  end

  def decode(_config, _content_type, data) when is_binary(data) do
    {:ok, data}
  end

  def decode(_config, _content_type, data) do
    {:error, %CodecError{operation: :decode, data: data}}
  end

  @doc """
  Encodes data using the JSON codec from the given config.
  """
  @spec encode(Config.t(), any) :: {:ok, any} | :error
  def encode(config, data)

  def encode(_config, nil), do: {:ok, ""}

  def encode(_config, data) when is_binary(data), do: {:ok, data}

  def encode(config, data) do
    with {:error, error} <- config.json_codec.encode(data) do
      {:error,
       %CodecError{operation: :encode, data: data, original_error: error}}
    end
  end
end
