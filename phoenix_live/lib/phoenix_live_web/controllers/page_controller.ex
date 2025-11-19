defmodule PhoenixLiveWeb.PageController do
  use PhoenixLiveWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
