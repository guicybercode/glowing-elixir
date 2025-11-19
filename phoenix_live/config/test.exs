import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :phoenix_live, PhoenixLiveWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "8zyt2vOb0eoO6pojN5879bZ1BjlRQPBrWx87oob8iNj4lhWjtonyzmpEwKtAQsgp",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Test environment variables
System.put_env("ADMIN_PASSWORD", System.get_env("ADMIN_PASSWORD") || "testeadm2323@")
System.put_env("ENCRYPTION_KEY_BASE", System.get_env("ENCRYPTION_KEY_BASE") || "phoenix_live_secure_key_2024")
