import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :chat_elixir, ChatElixir.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: System.get_env("DATABASE_URL"),
  database: "chat_elixir_test#{System.get_env("MIX_TEST_PARTITION")}",
  ssl: true,
  # Free tier db only allows 4 connections. Rolling deploys need pool_size*(n+1) connections where n is the number of app replicas.
  pool_size: 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :chat_elixir, ChatElixirWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  server: false

# In test we don't send emails.
config :chat_elixir, ChatElixir.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
