# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
use Mix.Config



config :twitter_engine_web,
  generators: [context_app: :twitter_engine]

# Configures the endpoint
config :twitter_engine_web, TwitterEngineWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "MTHPwdLkGCT8Fx4x6sQn7ec7VDWHUicX4niBXTsrPS2usGXM5Jb3chSZxnCdzxaK",
  render_errors: [view: TwitterEngineWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: TwitterEngineWeb.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
