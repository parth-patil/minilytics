defmodule Minilytics.Router do
  use Minilytics.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", Minilytics do
    pipe_through :api

    get "/get_report", ApiController, :get_report
    get "/distinct_values", ApiController, :get_distinct_values
  end
end
