defmodule RubberBand.Adapter do
  alias RubberBand.BulkOperation
  alias RubberBand.Client.Config
  alias RubberBand.Doc
  alias RubberBand.SearchResult

  @doc """
  Determines whether the index with the given name exists.
  """
  @callback index_exists?(
              config :: Config.t(),
              index_name_or_alias :: String.t()
            ) :: boolean

  @doc """
  Creates an index with the given name.
  """
  @callback create_index(
              config :: Config.t(),
              index_name :: String.t(),
              index_alias :: String.t(),
              settings :: %{optional(atom) => any},
              mappings :: %{optional(atom) => any}
            ) :: :ok | {:error, RubberBand.error()}

  @doc """
  Creates an index with the given name and a random suffix, then runs the
  callback function and creates an alias on the newly created index.
  """
  @callback create_index(
              config :: Config.t(),
              index_name :: String.t(),
              index_alias :: String.t(),
              settings :: %{optional(atom) => any},
              mappings :: %{optional(atom) => any},
              populate_fun :: (() -> :ok | {:error, any})
            ) :: :ok | {:error, RubberBand.error()}

  @doc """
  Drops the index with the given name.
  """
  @callback drop_index(config :: Config.t(), index_name_or_alias :: String.t()) ::
              :ok | {:error, RubberBand.error()}

  @doc """
  Determines whether the doc with the specified ID exists in the given index.
  """
  @callback doc_exists?(
              config :: Config.t(),
              index_name_or_alias :: String.t(),
              doc_id :: term
            ) :: boolean

  @doc """
  Gets the doc with the specified ID from the given index. Returns `nil` when no
  doc could be found.
  """
  @callback get_doc(
              config :: Config.t(),
              index_name :: String.t(),
              doc_id :: term
            ) :: nil | Doc.t()

  @doc """
  Performs a search on the given index.
  """
  @callback search(
              config :: Config.t(),
              index_name :: String.t(),
              search_opts :: RubberBand.search_opts()
            ) ::
              {:ok, RubberBand.SearchResult.t()}
              | {:error, RubberBand.error()}

  @doc """
  Stores a single doc in the given index.
  """
  @callback put_doc(
              config :: Config.t(),
              index_name :: String.t(),
              doc :: Doc.t()
            ) :: :ok | {:error, RubberBand.error()}

  @doc """
  Deletes a single doc from the index.
  """
  @callback delete_doc(config :: Config.t(), index_name :: String.t()) ::
              :ok | {:error, RubberBand.error()}

  @doc """
  Deletes multiple docs matching the given predicates.
  """
  @callback delete_docs_by_query(
              config :: Config.t(),
              index_name :: String.t(),
              search_opts :: RubberBand.search_opts()
            ) :: :ok | {:error, RubberBand.error()}

  @doc """
  Stores multiple docs in the given index.
  """
  @callback bulk(
              config :: Config.t(),
              index_name :: String.t(),
              operations :: Enum.t() | [RubberBand.bulk_operation()]
            ) ::
              {:ok, RubberBand.Client.Response.t()}
              | {:error, RubberBand.error()}
end
