# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :time_quantifier,
  ecto_repos: [TimeQuantifier.Repo]

# Configures the endpoint
config :time_quantifier, TimeQuantifierWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "qspOM4TZDMHnxVung1mlHD8zUYvO0yxg4A7YI8JqdQTPwovkCjafCHjsvOuYodvD",
  render_errors: [view: TimeQuantifierWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: TimeQuantifier.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :time_quantifier, TimeQuantifier.Auth.Guardian,
  issuer: "TimeQuantifier",
  secret_key: "QJwXY3Hcq7NHZOvP+JD5e/DQeg7opb6Cz/k8d0cbjvkUt/EdZPI3KjMlCtr5LA0N"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
