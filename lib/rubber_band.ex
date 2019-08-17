defmodule RubberBand do
  @moduledoc false

  @type index :: atom
  @type error :: Client.error()
  @type search_opts :: Keyword.t() | %{optional(atom) => any}
end
