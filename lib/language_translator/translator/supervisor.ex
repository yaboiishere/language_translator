defmodule LanguageTranslator.Translator.Supervisor do
  use Supervisor

  alias LanguageTranslator.Translator
  alias LanguageTranslator.GoogleApi.Translate
  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Repo

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children =
      children()

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp children do
    {:ok, languages} = Translate.get_languages()
    cleaned_languages = languages |> Enum.map(&Map.take(&1, [:code, :display_name]))

    {137, inserted_languages} =
      Repo.insert_all(Language, cleaned_languages,
        conflict_target: [:code],
        on_conflict: {:replace_all_except, [:id, :inserted_at]},
        returning: true
      )

    Enum.flat_map(inserted_languages, &create_worker/1)
  end

  defp create_worker(%Language{code: code} = language) do
    translator_id = String.to_atom(code <> "_translator")
    aggregator_id = String.to_atom(code <> "_aggregator")

    [
      %{id: translator_id, start: {Translator.GenServer, :start_link, [language]}},
      %{id: aggregator_id, start: {Translator.Aggregator, :start_link, [language]}}
    ]
  end
end
