defmodule NigiwikiWeb.PageController do
  use NigiwikiWeb, :controller

  alias Nigiwiki.Accounts

  def index(conn, _params) do
    case get_session(conn, :user_token) do
      nil ->
        {:ok, user} = Accounts.create_user(%{})
        user_token = Phoenix.Token.sign(NigiwikiWeb.Endpoint, "__salt__", user.id)
        conn = put_session(conn, :user_token, user_token)
        render conn, "index.html", %{
          user_token: user_token
        }
      user_token ->
        {:ok, user_id} = Phoenix.Token.verify(NigiwikiWeb.Endpoint, "__salt__", user_token, max_age: 86400)
        render conn, "index.html", %{
          user_token: user_token
        }
    end
  end
end
