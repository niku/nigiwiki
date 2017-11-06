defmodule NigiwikiWeb.PageController do
  use NigiwikiWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
