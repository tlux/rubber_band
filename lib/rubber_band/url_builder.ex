defmodule RubberBand.URLBuilder do
  @moduledoc false

  alias RubberBand.Config

  @separator "/"

  @spec build_url(Config.t(), nil | String.t() | [String.t()]) :: URI.t()
  def build_url(config, path_or_segments)

  def build_url(%{base_url: nil}, _path_or_segments) do
    raise ArgumentError, "Missing base URL"
  end

  def build_url(config, nil), do: URI.parse(config.base_url)

  def build_url(config, []), do: URI.parse(config.base_url)

  def build_url(config, path_segments) when is_list(path_segments) do
    base_url = URI.parse(config.base_url)
    base_path_segments = split_path(base_url.path)
    %{base_url | path: join_path_segments(base_path_segments ++ path_segments)}
  end

  def build_url(config, path) when is_binary(path) do
    build_url(config, split_path(path))
  end

  defp split_path(nil), do: []

  defp split_path(path) do
    String.split(path, @separator, trim: true)
  end

  defp join_path_segments(segments) do
    @separator <> Enum.join(segments, @separator)
  end
end