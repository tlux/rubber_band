defmodule RubberBand do
  @moduledoc false

  alias RubberBand.MultipleResultsError
  alias RubberBand.UnknownIndexError

  @type error ::
          Client.error() | MultipleResultsError.t() | UnknownIndexError.t()

  @type search_opts :: Keyword.t() | %{optional(atom) => any}

  @type bulk_operation ::
          {:index | :create | :update, Doc.t()} | {:delete, term}
end
