defmodule Minilytics.QueryExecutor do
  def execute_stats_query(query, server_host_and_port) do
      exec_query(query, "JSONCompact", server_host_and_port)
  end

  def execute_unique_values_query(dimensions_and_queries, server_host_and_port) do
    dimensions_and_queries
    |> Enum.map(fn {dim, query} -> Task.async(fn ->
          {dim, exec_query(query, "CSV", server_host_and_port)}
        end)
      end)
    |> Enum.map(&Task.await(&1, 3000))
    |> Enum.map(fn {d, resp} ->
      uniq_values = resp |> String.trim_trailing |> String.split("\n")
      {d, uniq_values}
      end)
    |> Enum.into(%{})
  end

  def exec_query(query, format, server_host_and_port) do
      query_with_format = query <> " FORMAT " <> format
      %HTTPoison.Response{body: body} = HTTPoison.get!(
          server_host_and_port,
          [],
          params: %{"query" => query_with_format}
      )
      body
  end
end