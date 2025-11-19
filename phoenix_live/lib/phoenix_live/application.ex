defmodule PhoenixLive.Application do
  use Application

  @impl true
  def start(_type, _args) do
    # Initialize ETS tables for rate limiting
    initialize_ets_tables()

    children = [
      PhoenixLiveWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:phoenix_live, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PhoenixLive.PubSub},
      PhoenixLiveWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: PhoenixLive.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Initialize ETS tables used by the application
  defp initialize_ets_tables do
    # Rate limiting table
    :ets.new(:rate_limit_data, [:named_table, :public, :set])
  end

  @impl true
  def config_change(changed, _new, removed) do
    PhoenixLiveWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
