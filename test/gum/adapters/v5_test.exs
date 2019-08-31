defmodule Gum.Adapters.V5Test do
  use ExUnit.Case, async: false

  alias Gum.Adapters.V5
  alias Gum.Config
  alias Gum.Doc
  alias Gum.GetResult
  alias Gum.Hit
  alias Gum.SearchResult

  @index_name "test-people"

  setup do
    config = %Config{
      client: ESClient.Config.new(base_url: "http://localhost:9200")
    }

    Client.delete(config, "test-*")
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
    @index_alias "#{@index_name}-alias"

    test "create index", context do
      refute V5.index_exists?(context.config, @index_name)
      refute V5.index_exists?(context.config, @index_alias)

      assert :ok =
               V5.create_index(
                 context.config,
                 @index_name,
                 @index_alias,
                 %{},
                 %{}
               )

      assert V5.index_exists?(context.config, @index_name)
      assert V5.index_exists?(context.config, @index_alias)

      resp = Client.get!(context.config, @index_alias)
      assert resp.data[:"#{@index_name}"][:aliases][:"#{@index_alias}"]

      assert resp.data[:"#{@index_name}"][:settings][:index][:mapping][
               :single_type
             ] == "true"
    end

    test "create index with custom settings and mappings", context do
      settings = %{
        analysis: %{
          analyzer: %{
            content: %{
              type: "custom",
              tokenizer: "whitespace"
            }
          }
        }
      }

      mappings = %{properties: %{name: %{type: "keyword"}}}

      assert :ok =
               V5.create_index(
                 context.config,
                 @index_name,
                 @index_alias,
                 settings,
                 mappings
               )

      resp = Client.get!(context.config, @index_alias)
      assert resp.data[:"#{@index_name}"][:mappings] == %{doc: mappings}

      assert resp.data[:"#{@index_name}"][:settings][:index][:analysis] ==
               settings[:analysis]
    end
  end

  describe "create_and_populate_index/6" do
    test "create index"

    test "create index with custom settings and mappings"

    test "error and remove index when populate callback returns error"

    test "error and remove index when populate callback raises"
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
      assert :ok = V5.drop_index(context.config, @index_name)
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

  describe "get_doc/3" do
    test "get doc", context do
      %{status_code: 200} = Client.put!(context.config, @index_name)

      doc_id = "1337"
      doc_source = %{name: "Hello World"}

      %{status_code: 201} =
        Client.put!(context.config, [@index_name, "doc", doc_id], doc_source)

      assert V5.get_doc(context.config, @index_name, doc_id) == %GetResult{
               doc: %{id: doc_id, source: doc_source},
               version: 1
             }
    end

    test "get nil when no doc found", context do
      assert V5.get_doc(context.config, "unknown-index", "1337") == nil
      assert V5.get_doc(context.config, @index_name, "1337") == nil
    end
  end

  describe "search/3" do
    test "search with hits", context do
      %{status_code: 200} = Client.put!(context.config, @index_name)

      doc = %Doc{
        id: "1337",
        source: %{name: "Hello World"}
      }

      :ok = V5.put_doc(context.config, @index_name, doc)

      assert {:ok, %SearchResult{hits: hits}} =
               V5.search(context.config, @index_name, %{
                 query: %{match: %{name: "Hello"}}
               })

      assert hits.entries == [
               %Hit{doc: doc, score: 0.25811607}
             ]
    end

    test "search with aggregations"
  end

  describe "put_doc/3" do
    test "put doc", context do
      %{status_code: 200} = Client.put!(context.config, @index_name)

      doc = %Doc{
        id: "1337",
        source: %{name: "Hello World"}
      }

      assert :ok = V5.put_doc(context.config, @index_name, doc)

      data = %{
        _id: doc.id,
        _index: "test-people",
        _source: doc.source,
        _type: "doc",
        _version: 1,
        found: true
      }

      assert %{data: ^data} =
               Client.get!(context.config, [@index_name, "doc", doc.id])
    end
  end

  describe "delete_doc/2" do
    test "delete doc", context do
      doc = %{
        id: "1337",
        source: %{name: "Hello World"}
      }

      %{status_code: 200} = Client.put!(context.config, @index_name)

      :ok = V5.put_doc(context.config, @index_name, doc)

      assert V5.doc_exists?(context.config, @index_name, doc.id)
      assert :ok = V5.delete_doc(context.config, @index_name, doc.id)
      refute V5.doc_exists?(context.config, @index_name, doc.id)
    end
  end

  describe "delete_docs_by_query/3" do
  end

  describe "bulk/3" do
  end
end