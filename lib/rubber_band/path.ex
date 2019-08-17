defmodule RubberBand.Path do
  @moduledoc """
  A module that provides utility functions to work with paths.
  """

  @typedoc """
  A type that defines a String containing path segments separated by slashes.
  """
  @type path :: String.t()

  @typedoc """
  A type that defines a list of path segments.
  """
  @type path_segments :: [String.t()]

  @typedoc """
  A type that defines a String containing path segments separated by slashes or
  a list of path segments.
  """
  @type t :: path | path_segments
end
