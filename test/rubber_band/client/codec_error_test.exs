defmodule RubberBand.Client.CodecErrorTest do
  use ExUnit.Case, async: true

  alias RubberBand.Client.CodecError

  describe "message/1" do
    test "decode error" do
      error = %CodecError{operation: :decode}

      assert CodecError.message(error) == "Unable to decode data"
    end

    test "encode error" do
      error = %CodecError{operation: :encode}

      assert CodecError.message(error) == "Unable to encode data"
    end
  end
end
