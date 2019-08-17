defmodule RubberBand.ClientTest do
  use ExUnit.Case, async: true

  import Mox

  alias RubberBand.Client
  alias RubberBand.Codec
  alias RubberBand.CodecError
  alias RubberBand.Config
  alias RubberBand.Drivers.Mock, as: MockDriver
  alias RubberBand.RequestError
  alias RubberBand.Response
  alias RubberBand.ResponseError
  alias RubberBand.Utils

  setup :verify_on_exit!

  @config %Config{driver: MockDriver, timeout: 5000}
  @opts [recv_timeout: 5000]
  @path "my-index/_search"
  @url Utils.build_url(@config, @path)

  describe "request/3" do
    test "success" do
      resp_data = %{my: %{resp: "data"}}

      expect(MockDriver, :request, fn :get, @url, "", [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert Client.request(@config, :get, @path) ==
               {:ok,
                %Response{
                  content_type: "application/json",
                  data: resp_data,
                  status_code: 200
                }}
    end

    test "decode error" do
      resp_body = "{{"

      expect(MockDriver, :request, fn :put, @url, "", [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: resp_body
         }}
      end)

      assert {:error, %CodecError{data: resp_body, operation: :decode}} =
               Client.request(@config, :put, @path)
    end

    test "request error" do
      reason = "Something went wrong"

      expect(MockDriver, :request, fn :head, @url, "", [], @opts ->
        {:error, %{reason: reason}}
      end)

      assert Client.request(@config, :head, @path) ==
               {:error, %RequestError{reason: reason}}
    end

    test "response error" do
      resp_data = %{
        error: %{
          col: 1,
          line: 3,
          reason: "Something went wrong",
          type: "unexpected_error"
        }
      }

      expect(MockDriver, :request, fn :delete, @url, "", [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert Client.request(@config, :delete, @path) ==
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
    test "success" do
      resp_data = %{my: %{resp: "data"}}

      expect(MockDriver, :request, fn :get, @url, "", [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert Client.request!(@config, :get, @path) ==
               %Response{
                 content_type: "application/json",
                 data: resp_data,
                 status_code: 200
               }
    end

    test "decode error" do
      resp_body = "{{"

      expect(MockDriver, :request, fn :put, @url, "", [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: resp_body
         }}
      end)

      assert_raise CodecError, "Unable to decode data", fn ->
        Client.request!(@config, :put, @path)
      end
    end

    test "request error" do
      reason = "Something went wrong"

      expect(MockDriver, :request, fn :post, @url, "", [], @opts ->
        {:error, %{reason: reason}}
      end)

      assert_raise RequestError, "Request error: #{reason}", fn ->
        Client.request!(@config, :post, @path)
      end
    end

    test "response error" do
      resp_data = %{
        error: %{
          col: 1,
          line: 3,
          reason: "Something went wrong",
          type: "unexpected_error"
        }
      }

      expect(MockDriver, :request, fn :delete, @url, "", [], @opts ->
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
                     Client.request!(@config, :delete, @path)
                   end
    end
  end

  describe "request/4" do
    test "success" do
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)
      resp_data = %{my: %{resp: "data"}}

      expect(MockDriver, :request, fn :post, @url, ^req_body, [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert Client.request(@config, :post, @path, req_data) ==
               {:ok,
                %Response{
                  content_type: "application/json",
                  data: resp_data,
                  status_code: 200
                }}
    end

    test "encode error" do
      req_data = {:some, :undecodable, "data"}

      assert {:error, %CodecError{data: req_data, operation: :encode}} =
               Client.request(@config, :post, @path, req_data)
    end

    test "decode error" do
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)
      resp_body = "{{"

      expect(MockDriver, :request, fn :put, @url, ^req_body, [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: resp_body
         }}
      end)

      assert {:error, %CodecError{data: resp_body, operation: :decode}} =
               Client.request(@config, :put, @path, req_data)
    end

    test "request error" do
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)
      reason = "Something went wrong"

      expect(MockDriver, :request, fn :put, @url, ^req_body, [], @opts ->
        {:error, %{reason: reason}}
      end)

      assert Client.request(@config, :put, @path, req_data) ==
               {:error, %RequestError{reason: reason}}
    end

    test "response error" do
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

      expect(MockDriver, :request, fn :delete, @url, ^req_body, [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert Client.request(@config, :delete, @path, req_data) ==
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
    test "success" do
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)
      resp_data = %{my: %{resp: "data"}}

      expect(MockDriver, :request, fn :post, @url, ^req_body, [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert Client.request!(@config, :post, @path, req_data) ==
               %Response{
                 content_type: "application/json",
                 data: resp_data,
                 status_code: 200
               }
    end

    test "encode error" do
      req_data = {:some, :undecodable, "data"}

      assert_raise CodecError, "Unable to encode data", fn ->
        Client.request!(@config, :post, @path, req_data)
      end
    end

    test "decode error" do
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)
      resp_body = "{{"

      expect(MockDriver, :request, fn :put, @url, ^req_body, [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: resp_body
         }}
      end)

      assert_raise CodecError, "Unable to decode data", fn ->
        Client.request!(@config, :put, @path, req_data)
      end
    end

    test "request error" do
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)
      reason = "Something went wrong"

      expect(MockDriver, :request, fn :put, @url, ^req_body, [], @opts ->
        {:error, %{reason: reason}}
      end)

      assert_raise RequestError, "Request error: #{reason}", fn ->
        Client.request!(@config, :put, @path, req_data)
      end
    end

    test "response error" do
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

      expect(MockDriver, :request, fn :delete, @url, ^req_body, [], @opts ->
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
                     Client.request!(@config, :delete, @path, req_data)
                   end
    end
  end

  describe "head/2" do
    test "success"
  end
end
