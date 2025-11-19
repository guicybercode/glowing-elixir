defmodule PhoenixLiveWeb.PageControllerTest do
  use PhoenixLiveWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Formulário de Candidatura"
  end
end
