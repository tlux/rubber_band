defmodule Gum.API do
  alias Gum.Config
  alias Gum.Doc
  alias Gum.GetResult
  alias Gum.SearchResult

  @doc """
  Stores multiple docs in the given index.
  """
  @callback bulk(
              config :: Config.t(),
              index :: Gum.index_key(),
              operations :: Enum.t() | [Gum.bulk_operation()]
            ) :: {:ok, ESClient.Response.t()} | {:error, Gum.error()}

  @doc """
  Creates an index with the given name and an alias.
  """
  @callback create_index(config :: Config.t(), index :: Gum.index_key()) ::
              :ok | {:error, Gum.error()}

  @doc """
  Creates an index with the given name and a random suffix, then runs the
  callback function and creates an alias on the newly created index.
  """
  @callback create_populated_index(
              config :: Config.t(),
              index :: Gum.index_key()
            ) :: :ok | {:error, Gum.error()}

  @doc """
  Deletes a single doc from the index.
  """
  @callback delete_doc(
              config :: Config.t(),
              index :: Gum.index_key(),
              doc_id :: term
            ) :: :ok | {:error, Gum.error()}

  @doc """
  Deletes multiple docs matching the given predicates.
  """
  @callback delete_docs_by_query(
              config :: Config.t(),
              index :: Gum.index_key(),
              search_opts :: Gum.search_opts()
            ) :: :ok | {:error, Gum.error()}

  @doc """
  Determines whether the doc with the specified ID exists in the given index.
  """
  @callback doc_exists?(
              config :: Config.t(),
              index :: Gum.index_key(),
              doc_id :: term
            ) :: boolean

  @doc """
  Drops the index with the given name.
  """
  @callback drop_index(config :: Config.t(), index :: Gum.index_key()) ::
              :ok | {:error, Gum.error()}

  @doc """
  Gets the doc with the specified ID from the given index. Returns `nil` when no
  doc could be found.
  """
  @callback get_doc(
              config :: Config.t(),
              index :: Gum.index_key(),
              doc_id :: term
            ) :: nil | GetResult.t()

  @doc """
  Determines whether the index with the given name exists.
  """
  @callback index_exists?(config :: Config.t(), index :: Gum.index_key()) ::
              boolean

  @doc """
  Stores a single doc in the given index.
  """
  @callback put_doc(
              config :: Config.t(),
              index :: Gum.index_key(),
              doc :: Doc.t()
            ) :: :ok | {:error, Gum.error()}

  @doc """
  Performs a search on the given index.
  """
  @callback search(
              config :: Config.t(),
              index :: Gum.index_key(),
              search_opts :: Gum.search_opts()
            ) :: {:ok, SearchResult.t()} | {:error, Gum.error()}
end
