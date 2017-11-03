defmodule NigiwaikiWeb.PageController do
  use NigiwaikiWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
