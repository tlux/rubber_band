defmodule RubberBand.ClientTest do
  use ExUnit.Case, async: true

  import Mox

  alias RubberBand.Client
  alias RubberBand.Client.Codec
  alias RubberBand.Client.CodecError
  alias RubberBand.Client.Config
  alias RubberBand.Client.Drivers.Mock, as: MockDriver
  alias RubberBand.Client.RequestError
  alias RubberBand.Client.Response
  alias RubberBand.Client.ResponseError
  alias RubberBand.Client.Utils

  @config %Config{driver: MockDriver, timeout: 5000}
  @opts [recv_timeout: 5000]
  @path "my-index/_search"
  @url Utils.build_url(@config, @path)

  setup :verify_on_exit!

  describe "use" do
    test "success" do
      defmodule SuccessTestClient do
        use Client, otp_app: :rubber_band
      end

      assert Client in SuccessTestClient.__info__(:attributes)[:behaviour]
    end

    test "raise when no :otp_app specified" do
      assert_raise KeyError, "key :otp_app not found in: []", fn ->
        defmodule ErrorTestClient do
          use Client
        end
      end
    end
  end

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

      assert_raise RequestError, "Request error: Something went wrong", fn ->
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

      expect(MockDriver, :request, fn :put, @url, ^req_body, [], @opts ->
        {:error, %{reason: "Something went wrong"}}
      end)

      assert_raise RequestError, "Request error: Something went wrong", fn ->
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
    test "success" do
      expect(MockDriver, :request, fn :head, @url, "", [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: ""
         }}
      end)

      assert Client.head(@config, @path) ==
               {:ok,
                %Response{
                  content_type: "application/json",
                  data: nil,
                  status_code: 200
                }}
    end

    test "request error" do
      reason = "Something went wrong"

      expect(MockDriver, :request, fn :head, @url, "", [], @opts ->
        {:error, %{reason: reason}}
      end)

      assert Client.head(@config, @path) ==
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

      expect(MockDriver, :request, fn :head, @url, "", [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert Client.head(@config, @path) ==
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

  describe "head!/2" do
    test "success" do
      expect(MockDriver, :request, fn :head, @url, "", [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: ""
         }}
      end)

      assert Client.head!(@config, @path) == %Response{
               content_type: "application/json",
               data: nil,
               status_code: 200
             }
    end

    test "request error" do
      reason = "Something went wrong"

      expect(MockDriver, :request, fn :head, @url, "", [], @opts ->
        {:error, %{reason: reason}}
      end)

      assert_raise RequestError, "Request error: Something went wrong", fn ->
        Client.head!(@config, @path)
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

      expect(MockDriver, :request, fn :head, @url, "", [], @opts ->
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
                     Client.head!(@config, @path)
                   end
    end
  end

  describe "get/2" do
    test "success" do
      expect(MockDriver, :request, fn :get, @url, "", [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: ""
         }}
      end)

      assert Client.get(@config, @path) ==
               {:ok,
                %Response{
                  content_type: "application/json",
                  data: nil,
                  status_code: 200
                }}
    end

    test "request error" do
      reason = "Something went wrong"

      expect(MockDriver, :request, fn :get, @url, "", [], @opts ->
        {:error, %{reason: reason}}
      end)

      assert Client.get(@config, @path) ==
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

      expect(MockDriver, :request, fn :get, @url, "", [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert Client.get(@config, @path) ==
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

  describe "get!/2" do
    test "success" do
      expect(MockDriver, :request, fn :get, @url, "", [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: ""
         }}
      end)

      assert Client.get!(@config, @path) == %Response{
               content_type: "application/json",
               data: nil,
               status_code: 200
             }
    end

    test "request error" do
      reason = "Something went wrong"

      expect(MockDriver, :request, fn :get, @url, "", [], @opts ->
        {:error, %{reason: reason}}
      end)

      assert_raise RequestError, "Request error: Something went wrong", fn ->
        Client.get!(@config, @path)
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

      expect(MockDriver, :request, fn :get, @url, "", [], @opts ->
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
                     Client.get!(@config, @path)
                   end
    end
  end

  describe "post/2" do
    test "success" do
      expect(MockDriver, :request, fn :post, @url, "", [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: ""
         }}
      end)

      assert Client.post(@config, @path) ==
               {:ok,
                %Response{
                  content_type: "application/json",
                  data: nil,
                  status_code: 200
                }}
    end

    test "request error" do
      reason = "Something went wrong"

      expect(MockDriver, :request, fn :post, @url, "", [], @opts ->
        {:error, %{reason: reason}}
      end)

      assert Client.post(@config, @path) ==
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

      expect(MockDriver, :request, fn :post, @url, "", [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert Client.post(@config, @path) ==
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

  describe "post!/2" do
    test "success" do
      expect(MockDriver, :request, fn :post, @url, "", [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: ""
         }}
      end)

      assert Client.post!(@config, @path) == %Response{
               content_type: "application/json",
               data: nil,
               status_code: 200
             }
    end

    test "request error" do
      reason = "Something went wrong"

      expect(MockDriver, :request, fn :post, @url, "", [], @opts ->
        {:error, %{reason: reason}}
      end)

      assert_raise RequestError, "Request error: Something went wrong", fn ->
        Client.post!(@config, @path)
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

      expect(MockDriver, :request, fn :post, @url, "", [], @opts ->
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
                     Client.post!(@config, @path)
                   end
    end
  end

  describe "post/3" do
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

      assert Client.post(@config, @path, req_data) ==
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
               Client.post(@config, @path, req_data)
    end

    test "decode error" do
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)
      resp_body = "{{"

      expect(MockDriver, :request, fn :post, @url, ^req_body, [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: resp_body
         }}
      end)

      assert {:error, %CodecError{data: resp_body, operation: :decode}} =
               Client.post(@config, @path, req_data)
    end

    test "request error" do
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)
      reason = "Something went wrong"

      expect(MockDriver, :request, fn :post, @url, ^req_body, [], @opts ->
        {:error, %{reason: reason}}
      end)

      assert Client.post(@config, @path, req_data) ==
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

      expect(MockDriver, :request, fn :post, @url, ^req_body, [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert Client.post(@config, @path, req_data) ==
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

  describe "post!/3" do
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

      assert Client.post!(@config, @path, req_data) ==
               %Response{
                 content_type: "application/json",
                 data: resp_data,
                 status_code: 200
               }
    end

    test "encode error" do
      req_data = {:some, :undecodable, "data"}

      assert_raise CodecError, "Unable to encode data", fn ->
        Client.post!(@config, @path, req_data)
      end
    end

    test "decode error" do
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)
      resp_body = "{{"

      expect(MockDriver, :request, fn :post, @url, ^req_body, [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: resp_body
         }}
      end)

      assert_raise CodecError, "Unable to decode data", fn ->
        Client.post!(@config, @path, req_data)
      end
    end

    test "request error" do
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)

      expect(MockDriver, :request, fn :post, @url, ^req_body, [], @opts ->
        {:error, %{reason: "Something went wrong"}}
      end)

      assert_raise RequestError, "Request error: Something went wrong", fn ->
        Client.post!(@config, @path, req_data)
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

      expect(MockDriver, :request, fn :post, @url, ^req_body, [], @opts ->
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
                     Client.post!(@config, @path, req_data)
                   end
    end
  end

  describe "put/2" do
    test "success" do
      expect(MockDriver, :request, fn :put, @url, "", [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: ""
         }}
      end)

      assert Client.put(@config, @path) ==
               {:ok,
                %Response{
                  content_type: "application/json",
                  data: nil,
                  status_code: 200
                }}
    end

    test "request error" do
      reason = "Something went wrong"

      expect(MockDriver, :request, fn :put, @url, "", [], @opts ->
        {:error, %{reason: reason}}
      end)

      assert Client.put(@config, @path) ==
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

      expect(MockDriver, :request, fn :put, @url, "", [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert Client.put(@config, @path) ==
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

  describe "put!/2" do
    test "success" do
      expect(MockDriver, :request, fn :put, @url, "", [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: ""
         }}
      end)

      assert Client.put!(@config, @path) == %Response{
               content_type: "application/json",
               data: nil,
               status_code: 200
             }
    end

    test "request error" do
      reason = "Something went wrong"

      expect(MockDriver, :request, fn :put, @url, "", [], @opts ->
        {:error, %{reason: reason}}
      end)

      assert_raise RequestError, "Request error: Something went wrong", fn ->
        Client.put!(@config, @path)
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

      expect(MockDriver, :request, fn :put, @url, "", [], @opts ->
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
                     Client.put!(@config, @path)
                   end
    end
  end

  describe "put/3" do
    test "success" do
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)
      resp_data = %{my: %{resp: "data"}}

      expect(MockDriver, :request, fn :put, @url, ^req_body, [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert Client.put(@config, @path, req_data) ==
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
               Client.put(@config, @path, req_data)
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
               Client.put(@config, @path, req_data)
    end

    test "request error" do
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)
      reason = "Something went wrong"

      expect(MockDriver, :request, fn :put, @url, ^req_body, [], @opts ->
        {:error, %{reason: reason}}
      end)

      assert Client.put(@config, @path, req_data) ==
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

      expect(MockDriver, :request, fn :put, @url, ^req_body, [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert Client.put(@config, @path, req_data) ==
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

  describe "put!/3" do
    test "success" do
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)
      resp_data = %{my: %{resp: "data"}}

      expect(MockDriver, :request, fn :put, @url, ^req_body, [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: Codec.encode!(@config, resp_data)
         }}
      end)

      assert Client.put!(@config, @path, req_data) ==
               %Response{
                 content_type: "application/json",
                 data: resp_data,
                 status_code: 200
               }
    end

    test "encode error" do
      req_data = {:some, :undecodable, "data"}

      assert_raise CodecError, "Unable to encode data", fn ->
        Client.put!(@config, @path, req_data)
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
        Client.put!(@config, @path, req_data)
      end
    end

    test "request error" do
      req_data = %{my: %{req: "data"}}
      req_body = Codec.encode!(@config, req_data)

      expect(MockDriver, :request, fn :put, @url, ^req_body, [], @opts ->
        {:error, %{reason: "Something went wrong"}}
      end)

      assert_raise RequestError, "Request error: Something went wrong", fn ->
        Client.put!(@config, @path, req_data)
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

      expect(MockDriver, :request, fn :put, @url, ^req_body, [], @opts ->
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
                     Client.put!(@config, @path, req_data)
                   end
    end
  end

  describe "delete/2" do
    test "success" do
      expect(MockDriver, :request, fn :delete, @url, "", [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: ""
         }}
      end)

      assert Client.delete(@config, @path) ==
               {:ok,
                %Response{
                  content_type: "application/json",
                  data: nil,
                  status_code: 200
                }}
    end

    test "request error" do
      reason = "Something went wrong"

      expect(MockDriver, :request, fn :delete, @url, "", [], @opts ->
        {:error, %{reason: reason}}
      end)

      assert Client.delete(@config, @path) ==
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

      assert Client.delete(@config, @path) ==
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

  describe "delete!/2" do
    test "success" do
      expect(MockDriver, :request, fn :delete, @url, "", [], @opts ->
        {:ok,
         %{
           status_code: 200,
           headers: [{"content-type", "application/json; charset=utf-8"}],
           body: ""
         }}
      end)

      assert Client.delete!(@config, @path) == %Response{
               content_type: "application/json",
               data: nil,
               status_code: 200
             }
    end

    test "request error" do
      reason = "Something went wrong"

      expect(MockDriver, :request, fn :delete, @url, "", [], @opts ->
        {:error, %{reason: reason}}
      end)

      assert_raise RequestError, "Request error: Something went wrong", fn ->
        Client.delete!(@config, @path)
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
                     Client.delete!(@config, @path)
                   end
    end
  end
end
