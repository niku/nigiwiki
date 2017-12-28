# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :nigiwiki,
  ecto_repos: [Nigiwiki.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :nigiwiki, NigiwikiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "k9KJsSQlIJr/E1trqW6k1VPvSx+5L7/7O7+hXa9ckmCsFnTnvtYbB+HasoXpxMZs",
  render_errors: [view: NigiwikiWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Nigiwiki.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
