defmodule Gum do
  @moduledoc false

  alias Gum.MultipleResultsError
  alias Gum.UnknownIndexError

  @type index_key :: atom

  @type error ::
          ESClient.error() | MultipleResultsError.t() | UnknownIndexError.t()

  @type search_opts :: Keyword.t() | %{optional(atom) => any}

  @type bulk_operation ::
          {:index | :create | :update, Doc.t()} | {:delete, term}
end
