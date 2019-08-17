defmodule RubberBand.Utils do
  @moduledoc false

  alias RubberBand.Client
  alias RubberBand.Config

  @separator "/"

  @spec split_path(nil | Client.path()) :: Client.path_segments()
  def split_path(path)

  def split_path(nil), do: []

  def split_path(path) when is_binary(path) do
    String.split(path, @separator, trim: true)
  end

  def split_path(segments) when is_list(segments) do
    Enum.flat_map(segments, &split_path/1)
  end

  @spec join_path(nil | Client.path_segments()) :: Client.path_str()
  def join_path(segments)

  def join_path([]), do: ""

  def join_path(segments) when is_list(segments) do
    segments
    |> Enum.flat_map(&split_path/1)
    |> Enum.join(@separator)
  end

  @spec absolute_join_path(nil | Client.path_segments()) :: Client.path_str()
  def absolute_join_path(segments) do
    @separator <> join_path(segments)
  end

  @spec build_url(Config.t(), nil | Client.path()) :: URI.t()
  def build_url(config, path)

  def build_url(%{base_url: nil}, _path_or_segments) do
    raise ArgumentError, "Missing base URL"
  end

  def build_url(config, path) do
    base_url = URI.parse(config.base_url)
    %{base_url | path: absolute_join_path([base_url.path, path])}
  end
end
