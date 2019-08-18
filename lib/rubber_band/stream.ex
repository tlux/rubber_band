defmodule RubberBand.Stream do
  defstruct [:config, :index, search_opts: %{}]

  @type t :: %__MODULE__{
          config: RubberBand.Config.t(),
          index: RubberBand.index(),
          search_opts: RubberBand.search_opts()
        }

  defimpl Collectable do
    def into(original) do
      # TODO
    end
  end

  defimpl Enumerable do
    def count(stream) do
      {:error, __MODULE__}
    end

    def member?(_stream, _element) do
      {:error, __MODULE__}
    end

    def reduce(stream, acc, fun) do
      # TODO
    end

    def slice(_stream) do
      {:error, __MODULE__}
    end
  end
end
