defmodule PhoenixLive.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PhoenixLiveWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:phoenix_live, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PhoenixLive.PubSub},
      PhoenixLiveWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: PhoenixLive.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PhoenixLiveWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
