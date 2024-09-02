defmodule Crazy8Web.EnsureSessionController do
  use Crazy8Web, :controller

  def index(conn, %{"name" => name} = params) do
    return_to = Map.get(params, "return_to", "/")

    conn
    |> put_session(:session_id, Nanoid.generate())
    |> put_session(:name, name)
    |> redirect(to: return_to)
  end
end
