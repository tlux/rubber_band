defmodule RubberBand.Client.URLBuilderTest do
  use ExUnit.Case, async: true

  alias RubberBand.Client.URLBuilder
  alias RubberBand.Config

  describe "build_url/1" do
    test "get URL when path nil" do
      base_url = "http://localhost:9200/root"
      config = %Config{base_url: base_url}

      assert URLBuilder.build_url(config, nil) == URI.parse(base_url)
    end

    test "get URL when path blank" do
      base_url = "http://localhost:9200/root"
      config = %Config{base_url: base_url}

      assert URLBuilder.build_url(config, "") == URI.parse(base_url)
    end

    test "get URL when path is slash" do
      base_url = "http://localhost:9200/root"
      config = %Config{base_url: base_url}

      assert URLBuilder.build_url(config, "/") == URI.parse(base_url)
    end

    test "get URL when base URL has trailing slash and path has leading slash" do
      base_url = "http://localhost:9200/root/"
      config = %Config{base_url: base_url}

      assert URLBuilder.build_url(config, "/my-path") ==
               URI.parse("http://localhost:9200/root/my-path")
    end

    test "get URL when base URL has trailing slash and path has no leading slash" do
      base_url = "http://localhost:9200/root/"
      config = %Config{base_url: base_url}

      assert URLBuilder.build_url(config, "my-path") ==
               URI.parse("http://localhost:9200/root/my-path")
    end

    test "get URL when base URL has no trailing slash and path has leading slash" do
      base_url = "http://localhost:9200/root"
      config = %Config{base_url: base_url}

      assert URLBuilder.build_url(config, "/my-path") ==
               URI.parse("http://localhost:9200/root/my-path")
    end

    test "get URL when base URL has no trailing slash and path has no leading slash" do
      base_url = "http://localhost:9200/root"
      config = %Config{base_url: base_url}

      assert URLBuilder.build_url(config, "my-path") ==
               URI.parse("http://localhost:9200/root/my-path")
    end
  end
end
