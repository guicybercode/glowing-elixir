defmodule PhoenixLiveWeb.HealthController do
  use PhoenixLiveWeb, :controller

  alias PhoenixLive.Repo

  def app(conn, _params) do
    # Simple app health check
    conn
    |> put_status(200)
    |> json(%{status: "ok", service: "app"})
  end

  def db(conn, _params) do
    # Database health check
    case Repo.query("SELECT 1") do
      {:ok, _result} ->
        conn
        |> put_status(200)
        |> json(%{status: "ok", service: "database"})

      {:error, _reason} ->
        conn
        |> put_status(503)
        |> json(%{status: "error", service: "database"})
    end
  end
end
