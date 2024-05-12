defmodule LanguageTranslator.Translator.Refresher do
  use GenServer
  require Logger

  def start_link(%{interval: interval}) do
    GenServer.start_link(__MODULE__, %{interval: interval})
  end

  def init(%{interval: interval}) do
    Process.send_after(self(), :refresh, interval)
    {:ok, %{interval: interval}}
  end

  def handle_info(:refresh, state) do
    Process.send_after(self(), :refresh, state.interval)
    {:noreply, state}
  end
end
