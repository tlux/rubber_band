defmodule RubberBand.ClientTest do
  use ExUnit.Case, async: true

  import Mox

  alias RubberBand.Client
  alias RubberBand.Client.Codec
  alias RubberBand.Client.CodecError
  alias RubberBand.Client.Config
  alias RubberBand.Client.URLBuilder
  alias RubberBand.Drivers.Mock, as: MockDriver
  alias RubberBand.RequestError
  alias RubberBand.Response
  alias RubberBand.ResponseError

  setup :verify_on_exit!

  @config %Config{driver: MockDriver, timeout: 5000}

  describe "request/3" do
    test "call driver" do
      verb = :get
      path = "my-index/_search"
      url = URLBuilder.build_url(@config, path)
      opts = [recv_timeout: @config.timeout]
      resp_data = %{my: %{resp: "data"}}

      expect(MockDriver, :request, fn ^verb, ^url, "{}", [], ^opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert Client.request(@config, verb, path) ==
               {:ok, %Response{data: resp_data, status_code: 200}}
    end

    test "decode error" do
      verb = :put
      path = "my-index/_search"
      url = URLBuilder.build_url(@config, path)
      opts = [recv_timeout: @config.timeout]
      resp_body = "{{"

      expect(MockDriver, :request, fn ^verb, ^url, "{}", [], ^opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: resp_body
         }}
      end)

      assert {:error, %CodecError{data: resp_body, operation: :decode}} =
               Client.request(@config, verb, path)
    end

    test "request error" do
      verb = :post
      path = "my-index/_search"
      url = URLBuilder.build_url(@config, path)
      opts = [recv_timeout: @config.timeout]
      error_id = 1337
      reason = "Something went wrong"

      expect(MockDriver, :request, fn ^verb, ^url, "{}", [], ^opts ->
        {:error, %{id: error_id, reason: reason}}
      end)

      assert Client.request(@config, verb, path) ==
               {:error, %RequestError{id: error_id, reason: reason}}
    end

    test "response error" do
      verb = :delete
      path = "my-index/_search"
      url = URLBuilder.build_url(@config, path)
      opts = [recv_timeout: @config.timeout]

      resp_data = %{
        error: %{
          col: 1,
          line: 3,
          reason: "Something went wrong",
          type: "unexpected_error"
        }
      }

      expect(MockDriver, :request, fn ^verb, ^url, "{}", [], ^opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert Client.request(@config, verb, path) ==
               {:error,
                %ResponseError{
                  col: 1,
                  data: resp_data,
                  line: 3,
                  reason: "Something went wrong",
                  status_code: 200,
                  type: "unexpected_error"
                }}
    end
  end

  describe "request!/3" do
    test "call driver" do
      verb = :get
      path = "my-index/_search"
      url = URLBuilder.build_url(@config, path)
      opts = [recv_timeout: @config.timeout]
      resp_data = %{my: %{resp: "data"}}

      expect(MockDriver, :request, fn ^verb, ^url, "{}", [], ^opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert Client.request!(@config, verb, path) ==
               %Response{data: resp_data, status_code: 200}
    end

    test "decode error" do
      verb = :put
      path = "my-index/_search"
      url = URLBuilder.build_url(@config, path)
      opts = [recv_timeout: @config.timeout]
      resp_body = "{{"

      expect(MockDriver, :request, fn ^verb, ^url, "{}", [], ^opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: resp_body
         }}
      end)

      assert_raise CodecError, "Unable to decode data", fn ->
        Client.request!(@config, verb, path)
      end
    end

    test "request error" do
      verb = :post
      path = "my-index/_search"
      url = URLBuilder.build_url(@config, path)
      opts = [recv_timeout: @config.timeout]
      error_id = 1337
      reason = "Something went wrong"

      expect(MockDriver, :request, fn ^verb, ^url, "{}", [], ^opts ->
        {:error, %{id: error_id, reason: reason}}
      end)

      assert_raise RequestError, "Request error: #{reason}", fn ->
        Client.request!(@config, verb, path)
      end
    end

    test "response error" do
      verb = :delete
      path = "my-index/_search"
      url = URLBuilder.build_url(@config, path)
      opts = [recv_timeout: @config.timeout]

      resp_data = %{
        error: %{
          col: 1,
          line: 3,
          reason: "Something went wrong",
          type: "unexpected_error"
        }
      }

      expect(MockDriver, :request, fn ^verb, ^url, "{}", [], ^opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert_raise ResponseError,
                   "Response error: Something went wrong (unexpected_error)",
                   fn ->
                     Client.request!(@config, verb, path)
                   end
    end
  end

  describe "request/4" do
    test "call driver" do
      verb = :get
      path = "my-index/_search"
      url = URLBuilder.build_url(@config, path)
      opts = [recv_timeout: @config.timeout]
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)
      resp_data = %{my: %{resp: "data"}}

      expect(MockDriver, :request, fn ^verb, ^url, ^req_body, [], ^opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert Client.request(@config, verb, path, req_data) ==
               {:ok, %Response{data: resp_data, status_code: 200}}
    end

    test "encode error" do
      verb = :post
      path = "my-index/_search"
      url = URLBuilder.build_url(@config, path)
      opts = [recv_timeout: @config.timeout]
      req_data = {:some, :undecodable, "data"}

      assert {:error, %CodecError{data: req_data, operation: :encode}} =
               Client.request(@config, verb, path, req_data)
    end

    test "decode error" do
      verb = :put
      path = "my-index/_search"
      url = URLBuilder.build_url(@config, path)
      opts = [recv_timeout: @config.timeout]
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)
      resp_body = "{{"

      expect(MockDriver, :request, fn ^verb, ^url, ^req_body, [], ^opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: resp_body
         }}
      end)

      assert {:error, %CodecError{data: resp_body, operation: :decode}} =
               Client.request(@config, verb, path, req_data)
    end

    test "request error" do
      verb = :post
      path = "my-index/_search"
      url = URLBuilder.build_url(@config, path)
      opts = [recv_timeout: @config.timeout]
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)
      error_id = 1337
      reason = "Something went wrong"

      expect(MockDriver, :request, fn ^verb, ^url, ^req_body, [], ^opts ->
        {:error, %{id: error_id, reason: reason}}
      end)

      assert Client.request(@config, verb, path, req_data) ==
               {:error, %RequestError{id: error_id, reason: reason}}
    end

    test "response error" do
      verb = :delete
      path = "my-index/_search"
      url = URLBuilder.build_url(@config, path)
      opts = [recv_timeout: @config.timeout]
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)

      resp_data = %{
        error: %{
          col: 1,
          line: 3,
          reason: "Something went wrong",
          type: "unexpected_error"
        }
      }

      expect(MockDriver, :request, fn ^verb, ^url, ^req_body, [], ^opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert Client.request(@config, verb, path, req_data) ==
               {:error,
                %ResponseError{
                  col: 1,
                  data: resp_data,
                  line: 3,
                  reason: "Something went wrong",
                  status_code: 200,
                  type: "unexpected_error"
                }}
    end
  end

  describe "request!/4" do
    test "call driver" do
      verb = :get
      path = "my-index/_search"
      url = URLBuilder.build_url(@config, path)
      opts = [recv_timeout: @config.timeout]
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)
      resp_data = %{my: %{resp: "data"}}

      expect(MockDriver, :request, fn ^verb, ^url, ^req_body, [], ^opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert Client.request!(@config, verb, path, req_data) ==
               %Response{data: resp_data, status_code: 200}
    end

    test "encode error" do
      verb = :post
      path = "my-index/_search"
      url = URLBuilder.build_url(@config, path)
      opts = [recv_timeout: @config.timeout]
      req_data = {:some, :undecodable, "data"}

      assert_raise CodecError, "Unable to encode data", fn ->
        Client.request!(@config, verb, path, req_data)
      end
    end

    test "decode error" do
      verb = :put
      path = "my-index/_search"
      url = URLBuilder.build_url(@config, path)
      opts = [recv_timeout: @config.timeout]
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)
      resp_body = "{{"

      expect(MockDriver, :request, fn ^verb, ^url, ^req_body, [], ^opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: resp_body
         }}
      end)

      assert_raise CodecError, "Unable to decode data", fn ->
        Client.request!(@config, verb, path, req_data)
      end
    end

    test "request error" do
      verb = :post
      path = "my-index/_search"
      url = URLBuilder.build_url(@config, path)
      opts = [recv_timeout: @config.timeout]
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)
      error_id = 1337
      reason = "Something went wrong"

      expect(MockDriver, :request, fn ^verb, ^url, ^req_body, [], ^opts ->
        {:error, %{id: error_id, reason: reason}}
      end)

      assert_raise RequestError, "Request error: #{reason}", fn ->
        Client.request!(@config, verb, path, req_data)
      end
    end

    test "response error" do
      verb = :delete
      path = "my-index/_search"
      url = URLBuilder.build_url(@config, path)
      opts = [recv_timeout: @config.timeout]
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)

      resp_data = %{
        error: %{
          col: 1,
          line: 3,
          reason: "Something went wrong",
          type: "unexpected_error"
        }
      }

      expect(MockDriver, :request, fn ^verb, ^url, ^req_body, [], ^opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert_raise ResponseError,
                   "Response error: Something went wrong (unexpected_error)",
                   fn ->
                     Client.request!(@config, verb, path, req_data)
                   end
    end
  end
end
