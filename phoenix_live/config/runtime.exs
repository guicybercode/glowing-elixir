import Config

if System.get_env("PHX_SERVER") do
  config :phoenix_live, PhoenixLiveWeb.Endpoint, server: true
end

if config_env() == :prod do
  config :ex_aws,
    access_key_id: System.get_env("BACKBLAZE_KEY_ID"),
    secret_access_key: System.get_env("BACKBLAZE_APP_KEY"),
    region: "us-west-002",
    s3: [
      scheme: "https://",
      host: "s3.us-west-002.backblazeb2.com",
      port: 443
    ]

  config :phoenix_live,
    backblaze_bucket: System.get_env("BACKBLAZE_BUCKET")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :phoenix_live, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :phoenix_live, PhoenixLiveWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base
end
