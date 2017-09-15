# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :minilytics, Minilytics.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ELO/Hjox+Ma7TsWGKVuimLpTxnx6r/AsHNfKaCJwyq5wj5txWGnX1LKRAvDvrutA",
  render_errors: [view: Minilytics.ErrorView, accepts: ~w(json)],
  pubsub: [name: Minilytics.PubSub,
           adapter: Phoenix.PubSub.PG2]

config :minilytics, :clickhouse,
  table: "",
  server: "",
  date_col: "date"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
