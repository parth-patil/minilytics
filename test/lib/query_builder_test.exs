defmodule Minilytics.QueryBuilderTest do
  use ExUnit.Case
  alias Minilytics.QueryBuilder

  test "build_distinct_values_query works" do
    args =
      %{
        table: "impressions",
        dimension: "country",
        filters: %{"urlid" => "1234", "gender" => "M"},
        start_date: "2017-01-01",
        end_date: "2017-01-31",
        date_column: "date"
      }

    {:ok, actual_query} = QueryBuilder.build_distinct_values_query(args)
    expected_query =
      "SELECT distinct country FROM impressions WHERE gender = 'M' AND urlid = 1234 AND date BETWEEN '2017-01-01' AND '2017-01-31'"

    assert actual_query == expected_query
  end

  test "build_distinct_values_query returns error when missing args" do
    args =
      %{
        dimension: "country",
        filters: %{"urlid" => "1234"},
        start_date: "2017-01-01",
        end_date: "2017-01-31",
        date_column: "date"
      }

    {:error, actual_error_msg} = QueryBuilder.build_distinct_values_query(args)
    expected_error_msg = "missing required field(s) [:table]"
    assert actual_error_msg == expected_error_msg
  end

  test "build_stats_query works" do
    args =
      %{
        table: "impressions",
        group_dimensions: ["country"],
        aggregations: %{"*" => "count", "tos" => "sum"},
        filters: %{"urlid" => "1234"},
        start_date: "2017-01-01",
        end_date: "2017-01-31",
        date_column: "date"
      }

    {:ok, actual_query} = QueryBuilder.build_stats_query(args)
    expected_query =
      "SELECT country, count(*), sum(tos) FROM impressions WHERE urlid = 1234 AND date BETWEEN '2017-01-01' AND '2017-01-31' GROUP BY country LIMIT 1000"

    assert actual_query == expected_query
  end
end