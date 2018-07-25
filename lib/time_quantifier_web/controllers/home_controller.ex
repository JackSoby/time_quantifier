defmodule TimeQuantifierWeb.HomeController do
  use TimeQuantifierWeb, :controller

  alias TimeQuantifier.Auth
  alias TimeQuantifier.Auth.User
  alias TimeQuantifier.Auth.Guardian

  def index(conn, _params) do
    changeset = Auth.change_user(%User{})
    maybe_user = Guardian.Plug.current_resource(conn)

    conn
    |> render("index.html")
  end
end
