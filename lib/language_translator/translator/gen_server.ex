defmodule LanguageTranslator.Translator.GenServer do
  use GenServer
  require Logger

  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Translator.ProcessGroup
  alias LanguageTranslator.GoogleApi.Translate
  alias LanguageTranslator.Repo

  defstruct [:language]

  def start_link(%Language{} = language) do
    name = String.to_atom(language.code <> "_translator")
    GenServer.start_link(__MODULE__, %__MODULE__{language: language}, name: name)
  end

  def translate(pid, source_language, word, ref) do
    GenServer.cast(pid, {:translate, source_language, word, ref})
  end

  def init(state) do
    ProcessGroup.join(self())
    # {:ok, {:continue, {:persist_language, state}}}
    {:ok, state}
  end

  def handle_continue({:persist_language, %{language: language} = init_state}, _state) do
    changeset = Language.changeset(language, %{})

    {:ok, language} =
      Repo.insert(changeset,
        conflict_target: [:code],
        on_conflict: {:replace_all_except, [:id, :inserted_at]},
        returning: true
      )

    {:noreply, %{init_state | language: language}}
  end

  def handle_info(
        {:translate, source_language, word, caller_ref},
        %{language: source_language} = state
      ) do
    if caller_ref do
      {caller, ref} = caller_ref
      send(caller, {:translated, source_language, word, ref})
    end

    {:noreply, state}
  end

  def handle_info(
        {:translate, source_language, word, caller_ref},
        %{language: target_language} = state
      ) do
    translation = Translate.translate(source_language, target_language, word)

    if caller_ref do
      {caller, ref} = caller_ref

      case translation do
        {:ok, translation} -> send(caller, {:translated, target_language, translation, ref})
        {:error, _} -> send(caller, {:error, target_language, ref})
      end
    end

    {:noreply, state}
  end

  def terminate(_reason, _state) do
    Logger.error("Terminating #{inspect(self())}")
    ProcessGroup.leave(self())
    :ok
  end
end
