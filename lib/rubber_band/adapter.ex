defmodule RubberBand.Adapter do
  alias RubberBand.Client
  alias RubberBand.Client.Response
  alias RubberBand.Config
  alias RubberBand.Doc
  alias RubberBand.SearchResult

  @doc """
  Determines whether the index with the given name exists.
  """
  @callback index_exists?(config :: Config.t(), index :: RubberBand.index()) ::
              boolean

  @doc """
  Creates an index with the given name and a random suffix, then runs the
  callback function and creates an alias on the newly created index.
  """
  @callback create_index(
              config :: Config.t(),
              index :: RubberBand.index(),
              callback_fun :: nil | (() -> :ok | {:error, any})
            ) :: :ok | {:error, RubberBand.error()}

  @doc """
  Drops the index with the given name.
  """
  @callback drop_index(config :: Config.t(), index :: RubberBand.index()) ::
              :ok | {:error, RubberBand.error()}

  @doc """
  Determines whether the doc with the specified ID exists in the given index.
  """
  @callback doc_exists?(
              config :: Config.t(),
              index :: RubberBand.index(),
              doc_id :: term
            ) :: boolean

  @doc """
  Gets the doc with the specified ID from the given index. Returns `nil` when no
  doc could be found.
  """
  @callback get_doc(
              config :: Config.t(),
              index :: RubberBand.index(),
              doc_id :: term
            ) :: nil | Doc.t()

  @doc """
  Stores multiple docs in the given index.
  """
  @callback put_docs(
              config :: Config.t(),
              index :: RubberBand.index(),
              docs :: Enum.t() | [Doc.t()]
            ) :: :ok | {:error, RubberBand.error()}

  @doc """
  Performs a search on the given index.
  """
  @callback search(
              config :: Config.t(),
              index :: RubberBand.index(),
              search_opts :: RubberBand.search_opts()
            ) :: {:ok, SearchResult.t()} | {:error, RubberBand.error()}
end
