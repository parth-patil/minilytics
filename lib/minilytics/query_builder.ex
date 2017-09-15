defmodule Minilytics.QueryBuilder do
    def build_distinct_values_query(table, options) do
        [
            dimension: dimension,
            filters: filters,
            start_date: start_date,
            end_date: end_date,
            date_column: date_column
        ] = options

        where_clause = build_where_clause(start_date, end_date, date_column, filters)

        [
            "SELECT distinct #{dimension}",
            "FROM #{table}",
            "WHERE #{where_clause}"
        ]
        |> Enum.join(" ")
    end

    def build_stats_query(table, options) do
        filters = options[:filters]
        group_dimensions = options[:group_dimensions]
        aggregations = options[:aggregations]
        date_column = options[:date_column]
        start_date = options[:start_date]
        end_date = options[:end_date]
        limit = Keyword.get(options, :limit, 1000)

        select_cols = build_select_cols(group_dimensions, aggregations)
        where_clause = build_where_clause(start_date, end_date, date_column, filters)
        group_clause = group_dimensions |> Enum.join(",")
        
        [
            "SELECT #{select_cols}",
            "FROM #{table}",
            "WHERE #{where_clause}",
            "GROUP BY #{group_clause}",
            "LIMIT #{limit}"
        ]
        |> Enum.join(" ")
    end

    def build_select_cols(group_dimensions, aggregations) do
        joined_group_dims = group_dimensions |> Enum.join(",")
        joined_aggregation =
            aggregations
            |> Enum.map(fn {dim, agg_func} -> "#{agg_func}(#{dim})" end)
            |> Enum.join(",")

        "#{joined_group_dims}, #{joined_aggregation}"
    end

    def build_where_clause(start_date, end_date, date_column, filters) do
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
end