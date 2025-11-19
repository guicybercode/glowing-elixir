defmodule PhoenixLiveWeb.Router do
  use PhoenixLiveWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PhoenixLiveWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :admin_auth do
    plug :admin_required
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

scope "/", PhoenixLiveWeb do
  pipe_through :browser

  live "/", ApplicationLive, :index

  # Hidden admin routes
  get "/admin/login", PageController, :admin_login
  post "/admin/authenticate", PageController, :authenticate
end

scope "/admin", PhoenixLiveWeb do
  pipe_through [:browser, :admin_auth]

  live "/dashboard", AdminLive, :index
  get "/logout", PageController, :admin_logout
end

  # Admin authentication plug
  defp admin_required(conn, _opts) do
    case get_session(conn, :admin_authenticated) do
      true -> conn
      _ -> conn
           |> redirect(to: "/admin/login")
           |> halt()
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", PhoenixLiveWeb do
  #   pipe_through :api
  # end
end
