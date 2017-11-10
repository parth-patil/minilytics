defmodule Minilytics.QueryBuilder do
  def build_distinct_values_query(args) when is_map(args) do
    required_args = [:table, :dimension, :filters, :start_date, :end_date, :date_column]
    missing_fields = get_missing_fields(args, required_args)
    has_required_fields = length(missing_fields) == 0

    if (has_required_fields) do
      %{
        table: table,
        dimension: dimension,
        filters: filters,
        start_date: start_date,
        end_date: end_date,
        date_column: date_column
      } = args

      where_clause = build_where_clause(start_date, end_date, date_column, filters)

      query =
        [
          "SELECT distinct #{dimension}",
          "FROM #{table}",
          "WHERE #{where_clause}"
        ]
        |> Enum.join(" ")

      {:ok, query}
    else
      {:error, "missing required field(s) #{inspect(missing_fields)}"}
    end
  end

  def build_stats_query(args) when is_map(args) do
    required_args = [:table, :filters, :group_dimensions, :aggregations, :start_date, :end_date, :date_column]
    missing_fields = get_missing_fields(args, required_args)
    has_required_fields = length(missing_fields) == 0

    if (has_required_fields) do
      table = args[:table]
      filters = args[:filters]
      group_dimensions = args[:group_dimensions]
      aggregations = args[:aggregations]
      date_column = args[:date_column]
      start_date = args[:start_date]
      end_date = args[:end_date]
      limit = Map.get(args, :limit, 1000)

      select_cols = build_select_cols(group_dimensions, aggregations)
      where_clause = build_where_clause(start_date, end_date, date_column, filters)
      group_clause = group_dimensions |> Enum.join(",")
      
      query =
        [
          "SELECT #{select_cols}",
          "FROM #{table}",
          "WHERE #{where_clause}",
          "GROUP BY #{group_clause}",
          "LIMIT #{limit}"
        ]
        |> Enum.join(" ")

      {:ok, query}
    else
      {:error, "missing required field(s) #{inspect(missing_fields)}"}
    end
  end

  def build_select_cols(group_dimensions, aggregations) do
    joined_group_dims = group_dimensions |> Enum.join(",")
    joined_aggregation =
      aggregations
      |> Enum.map(fn {dim, agg_func} -> "#{agg_func}(#{dim})" end)
      |> Enum.join(", ")

    "#{joined_group_dims}, #{joined_aggregation}"
  end

  def build_where_clause(start_date, end_date, date_column, filters \\ %{}) do
    date_clause = "#{date_column} BETWEEN '#{start_date}' AND '#{end_date}'"

    if Map.size(filters) > 0 do
      filters_joined =
        filters
        |> Enum.map(fn {dim, value} -> 
          if (is_numeric(value)) do
            "#{dim} = #{value}"
          else
            "#{dim} = '#{value}'"
          end
        end)
        |> Enum.join(" AND ")

      filters_joined <> " AND #{date_clause}"
    else
      date_clause
    end
  end

  def is_numeric(str) do
    case Float.parse(str) do
      {_num, ""} -> true
      _          -> false
    end
  end

  defp get_missing_fields(mp, fields) do
    fields |> Enum.filter(fn f -> !Map.has_key?(mp, f) end)
  end
end