defmodule ListOperations do
  def list_sum(list) do
    list_sum(list, 0)
  end

  def transform(list) do
    new_list = Enum.map(Enum.reverse(List.flatten(list)), fn(x) -> x * x end)
  end

  defp list_sum([], acc) do
    acc
  end

  defp list_sum(list, acc) do
    [head | tail] = list
    list_sum(tail, acc + head)
  end
end