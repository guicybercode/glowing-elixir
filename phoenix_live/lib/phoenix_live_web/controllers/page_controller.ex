defmodule PhoenixLiveWeb.PageController do
  use PhoenixLiveWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def admin_login(conn, _params) do
    render(conn, :admin_login)
  end

  def authenticate(conn, %{"password" => password}) do
    admin_password = System.get_env("ADMIN_PASSWORD") ||
      raise """
      ADMIN_PASSWORD environment variable is required.
      Set it to your admin password, for example: testeadm2323@
      """

    if password == admin_password do
      conn
      |> put_session(:admin_authenticated, true)
      |> redirect(to: "/admin/dashboard")
    else
      conn
      |> put_flash(:error, "Senha incorreta")
      |> redirect(to: "/admin/login")
    end
  end

  def admin_logout(conn, _params) do
    conn
    |> delete_session(:admin_authenticated)
    |> redirect(to: "/")
  end
end
