defmodule NigiwikiWeb.PageControllerTest do
  use NigiwikiWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "elm-app"
  end
end
