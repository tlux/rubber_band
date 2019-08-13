defmodule RubberBand.Adapter do
  @moduledoc """
  An adapter behavior that allows implementation for custom Elasticsearch
  adapters.
  """

  alias RubberBand.AdapterContext
  alias RubberBand.Hit

  @doc """
  Determines whether an index exists.
  """
  @callback index_exists?(context :: AdapterContext.t()) :: boolean

  @doc """
  Creates a new empty index using the store configured for the index.
  """
  @callback create_index(context :: AdapterContext.t()) ::
              :ok | {:error, RubberBand.error()}

  @doc """
  Drops an existing index.
  """
  @callback drop_index(context :: AdapterContext.t()) ::
              :ok | {:error, RubberBand.error()}

  @doc """
  Determines whether the document with the given exists in the index.
  """
  @callback doc_exists?(context :: AdapterContext.t(), id :: term) :: boolean

  @doc """
  Gets the record for the given ID from the given index.
  """
  @callback get_doc(context :: AdapterContext.t(), id :: term) :: nil | Hit.t()

  @doc """
  Searches the given index using the specified query.
  """
  @callback search(
              context :: AdapterContext.t(),
              search_opts :: %{optional(atom) => any}
            ) :: {:ok, SearchResult.t()} | {:error, RubberBand.error()}

  @doc """
  Put multiple docs at once in the index.
  """
  @callback put_records(
              context :: AdapterContext.t(),
              data :: Enum.t(),
              await :: boolean
            ) :: :ok | {:error, RubberBand.error()}

  @doc """
  Delete a single record from the index.
  """
  @callback delete_doc(
              context :: AdapterContext.t(),
              id :: term,
              await :: boolean
            ) :: :ok | {:error, RubberBand.error()}

  @doc """
  Delete one or multiple records from the index using the given query.
  """
  @callback delete_docs_by_query(
              context :: AdapterContext.t(),
              search_opts :: %{optional(atom) => any},
              await :: boolean
            ) :: :ok | {:error, RubberBand.error()}
end
