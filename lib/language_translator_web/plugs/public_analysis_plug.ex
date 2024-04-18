defmodule LanguageTranslatorWeb.Plugs.PublicAnalysisPlug do
  import Plug.Conn
  alias LanguageTranslator.Models
  alias LanguageTranslator.Repo
  def init(opts), do: opts

  def call(%{params: %{"id" => analysis_id}} = conn, opts) do
    current_user = Map.get(conn.assigns, :current_user)

    if analysis_id do
      Repo.get(Models.Analysis, analysis_id)
      |> case do
        %{is_public: true} when opts == :show ->
          conn

        _analysis when is_nil(current_user) ->
          not_authorized(conn)

        analysis when analysis.user_id == current_user.id ->
          conn

        _ ->
          not_authorized(conn)
      end
    else
      not_found(conn)
    end
  end

  def not_found(conn) do
    conn
    |> send_resp(404, "Not Found")
    |> halt()
  end

  def not_authorized(conn) do
    conn
    |> send_resp(401, "Unauthorized")
    |> halt()
  end
end
