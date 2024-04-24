defmodule LanguageTranslatorWeb.UserLive.Index do
  use LanguageTranslatorWeb, :live_view
  alias LanguageTranslator.Accounts.User
  alias LanguageTranslator.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user =
      session
      |> Map.get("user_token")
      |> case do
        nil -> nil
        user_token -> Accounts.get_user_by_session_token(user_token)
      end

    socket =
      socket
      |> assign_new(:current_user, fn -> current_user end)

    {:ok,
     stream(
       socket,
       :users,
       User.get_all()
     )}
  end
end
