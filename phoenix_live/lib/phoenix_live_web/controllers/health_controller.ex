defmodule PhoenixLiveWeb.HealthController do
  use PhoenixLiveWeb, :controller

  def app(conn, _params) do
    # Simple app health check
    conn
    |> put_status(200)
    |> json(%{status: "ok", service: "app"})
  end
end
