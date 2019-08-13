defmodule RubberBand do
  alias RubberBand.ResponseError
  alias RubberBand.UnknownIndexError

  @type error :: ResponseError.t() | UnknownIndexError.t()
end
