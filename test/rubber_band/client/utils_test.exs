defmodule RubberBand.Client.UtilsTest do
  use ExUnit.Case, async: true

  alias RubberBand.Client.Config
  alias RubberBand.Client.Utils

  describe "split_path/1" do
    test "get empty list when arg nil" do
      assert Utils.split_path(nil) == []
    end

    test "get list of segments" do
      assert Utils.split_path("this/is/my/path") == ["this", "is", "my", "path"]
    end

    test "get flat list of sements" do
      assert Utils.split_path([["this/is"], "my", ["path"]]) == [
               "this",
               "is",
               "my",
               "path"
             ]
    end

    test "strip empty segments" do
      assert Utils.split_path("this///is/my/path") == [
               "this",
               "is",
               "my",
               "path"
             ]

      assert Utils.split_path("//this///is/my/path/") == [
               "this",
               "is",
               "my",
               "path"
             ]
    end
  end

  describe "join_path/1" do
    test "get empty string when arg empty list" do
      assert Utils.join_path([]) == ""
    end

    test "get path string" do
      assert Utils.join_path(["this", "is", "my", "path"]) == "this/is/my/path"
    end

    test "get path string from nested segments" do
      assert Utils.join_path(["this", "is", ["my", "path"]]) ==
               "this/is/my/path"
    end

    test "ignore empty segments" do
      assert Utils.join_path(["this", nil, "", "is", "my", "path"]) ==
               "this/is/my/path"
    end
  end

  describe "absolute_join_path/1" do
    test "get empty string when arg empty list" do
      assert Utils.absolute_join_path([]) == "/"
    end

    test "get path string" do
      assert Utils.absolute_join_path(["this", "is", "my", "path"]) ==
               "/this/is/my/path"
    end

    test "get path string from nested segments" do
      assert Utils.absolute_join_path(["this", "is", ["my", "path"]]) ==
               "/this/is/my/path"
    end

    test "ignore empty segments" do
      assert Utils.absolute_join_path(["this", nil, "", "is", "my", "path"]) ==
               "/this/is/my/path"
    end
  end

  describe "build_url/1" do
    test "get URL when path nil" do
      base_url = "http://localhost:9200/root"
      config = %Config{base_url: base_url}

      assert Utils.build_url(config, nil) == URI.parse(base_url)
    end

    test "get URL when path blank" do
      base_url = "http://localhost:9200/root"
      config = %Config{base_url: base_url}

      assert Utils.build_url(config, "") == URI.parse(base_url)
    end

    test "get URL when path is slash" do
      base_url = "http://localhost:9200/root"
      config = %Config{base_url: base_url}

      assert Utils.build_url(config, "/") == URI.parse(base_url)
    end

    test "get URL when base URL has trailing slash and path has leading slash" do
      config = %Config{base_url: "http://localhost:9200/root/"}

      assert Utils.build_url(config, "/my-path") ==
               URI.parse("http://localhost:9200/root/my-path")
    end

    test "get URL when base URL has trailing slash and path has no leading slash" do
      config = %Config{base_url: "http://localhost:9200/root/"}

      assert Utils.build_url(config, "my-path") ==
               URI.parse("http://localhost:9200/root/my-path")
    end

    test "get URL when base URL has no trailing slash and path has leading slash" do
      config = %Config{base_url: "http://localhost:9200/root"}

      assert Utils.build_url(config, "/my-path") ==
               URI.parse("http://localhost:9200/root/my-path")
    end

    test "get URL when base URL has no trailing slash and path has no leading slash" do
      config = %Config{base_url: "http://localhost:9200/root"}

      assert Utils.build_url(config, "my-path") ==
               URI.parse("http://localhost:9200/root/my-path")
    end

    test "get URL with path segments" do
      config = %Config{base_url: "http://localhost:9200/root"}

      assert Utils.build_url(config, ["my-path", "my-nested-path"]) ==
               URI.parse("http://localhost:9200/root/my-path/my-nested-path")
    end

    test "get URL when base URL has no path segments" do
      config = %Config{base_url: "http://localhost:9200"}

      assert Utils.build_url(config, "my-index/_search") ==
               URI.parse("http://localhost:9200/my-index/_search")
    end

    test "raise when base URL nil" do
      assert_raise ArgumentError, "Missing base URL", fn ->
        Utils.build_url(%Config{base_url: nil}, "another-path")
      end
    end
  end
end
