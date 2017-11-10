defmodule Minilytics.ApiController do
  use Minilytics.Web, :controller
  alias Minilytics.QueryBuilder
  alias Minilytics.QueryExecutor

  def get_report(conn, params) do
    %{
      "filters" => raw_filters,
      "group_by" => raw_group_by,
      "aggregations" => raw_aggregations,
      "start_date" => start_date,
      "end_date" => end_date
    } = params

    filters = extract_map(raw_filters)
    group_dimensions = raw_group_by |> String.split(",")
    aggregations = extract_map(raw_aggregations)

    table = Application.get_env(:minilytics, :clickhouse)[:table]
    date_column = Application.get_env(:minilytics, :clickhouse)[:date_col]
    clickhouse_server = Application.get_env(:minilytics, :clickhouse)[:server]

    args = %{
      table: table,
      filters: filters,
      group_dimensions: group_dimensions,
      aggregations: aggregations,
      start_date: start_date,
      end_date: end_date,
      date_column: date_column
    }
    {:ok, query} = QueryBuilder.build_stats_query(args)
    response = QueryExecutor.execute_stats_query(query , clickhouse_server)

    conn
    |> put_status(:ok)
    |> json(%{
      filters: filters,
      group_dimensions: group_dimensions,
      aggregations: aggregations,
      query: query,
      response: Poison.Parser.parse!(response)
      })
  end

  def get_distinct_values(conn, params) do
    filters = extract_map(params["filters"])
    dimensions = params["dimensions"] |> String.split(",")
    start_date = params["start_date"]
    end_date = params["end_date"]

    table = Application.get_env(:minilytics, :clickhouse)[:table]
    date_column = Application.get_env(:minilytics, :clickhouse)[:date_col]
    clickhouse_server = Application.get_env(:minilytics, :clickhouse)[:server]

    # construct the query for click house
    unique_values =
      dimensions
      |> Enum.map(fn dim ->
        args = %{
          table: table,
          dimension: dim,
          filters: filters,
          start_date: start_date,
          end_date: end_date,
          date_column: date_column
        }
        {:ok, query} = QueryBuilder.build_distinct_values_query(args)
        {dim, query}
      end)
      |> QueryExecutor.execute_unique_values_query(clickhouse_server)

    conn
    |> put_status(:ok)
    |> json(%{
      filters: filters,
      dimensions: dimensions,
      unique_values: unique_values
      })
  end

  defp extract_map(str) do
    str
    |> String.split(",")
    |> Enum.map(fn d -> [k,v] = String.split(d , ":"); {k,v} end )
    |> Enum.into(%{})
  end
end