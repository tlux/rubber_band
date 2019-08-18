defmodule RubberBand.Adapters.V5Test do
  use ExUnit.Case, async: false

  alias RubberBand.Adapters.V5
  alias RubberBand.Client
  alias RubberBand.Client.Config

  @index_name "test-people"

  setup do
    config = %Config{base_url: "http://localhost:9200"}
    Client.delete(config, @index_name)
    {:ok, config: config}
  end

  describe "index_exists?/2" do
    test "true when index exists", context do
      %{status_code: 200} = Client.put!(context.config, @index_name)

      assert V5.index_exists?(context.config, @index_name) == true
    end

    test "false when index not exists", context do
      assert V5.index_exists?(context.config, @index_name) == false
    end
  end

  describe "create_index/5" do
    # TODO
  end

  describe "create_index/6" do
    # TODO
  end

  describe "drop_index/2" do
    test "drop existing index", context do
      %{status_code: 200} = Client.put!(context.config, @index_name)

      assert V5.index_exists?(context.config, @index_name)
      assert :ok = V5.drop_index(context.config, @index_name)
      refute V5.index_exists?(context.config, @index_name)
    end

    test "drop missing index", context do
      refute V5.index_exists?(context.config, @index_name)

      assert {:error, %{status_code: 404}} =
               V5.drop_index(context.config, @index_name)

      refute V5.index_exists?(context.config, @index_name)
    end
  end

  describe "doc_exists?/3" do
    test "true when index exists", context do
      doc_id = "1337"

      %{status_code: 200} = Client.put!(context.config, @index_name)

      %{status_code: 201} =
        Client.put!(context.config, [@index_name, "doc", doc_id], %{
          "name" => "Hello World"
        })

      assert V5.doc_exists?(context.config, @index_name, doc_id) == true
    end

    test "false when index not exists", context do
      assert V5.doc_exists?(context.config, @index_name, "1337") == false
    end
  end
end
