defmodule LanguageTranslator.Config do
  use GenServer

  def google_translate() do
    Application.get_env(:language_translator, :google_translate)
  end

  def google_translate_project_id do
    google_translate()[:project_id]
  end

  def google_translate_url do
    "#{google_translate_base_url()}#{google_translate_project_id()}/locations/global"
  end

  defp google_translate_base_url do
    google_translate()[:base_url]
  end

  def google_translate_access_key do
    GenServer.call(__MODULE__, :get_google_translate_access_key)
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_args) do
    Process.send_after(self(), :refresh_google_translate_access_key, 0)
    {:ok, {Time.utc_now(), refresh_google_translate_access_key()}}
  end

  def handle_call(:get_google_translate_access_key, _from, {_creation_time, access_key} = state) do
    {:reply, access_key, state}
  end

  def handle_info(:refresh_google_translate_access_key, {_creation_time, _access_key}) do
    new_access_key = refresh_google_translate_access_key()
    Process.send_after(self(), :refresh_google_translate_access_key, 3600 * 1000)
    {:noreply, {Time.utc_now(), new_access_key}}
  end

  defp refresh_google_translate_access_key do
    System.cmd("gcloud", ["auth", "print-access-token"])
    |> case do
      {token, 0} ->
        String.trim(token)

      {err, code} ->
        raise "Failed to get access token: #{code}, Error: #{err}"
    end
  end
end
