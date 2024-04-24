defmodule LanguageTranslatorWeb.Plugs.RequireAdmin do
  import Plug.Conn
  def init(opts), do: opts

  def call(conn, _opts) do
    current_user = Map.get(conn.assigns, :current_user)

    if current_user && current_user.is_admin do
      conn
    else
      not_authorized(conn)
    end
  end

  defp not_authorized(conn) do
    conn
    |> send_resp(401, "Unauthorized")
    |> halt()
  end
end
