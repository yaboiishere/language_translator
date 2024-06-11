defmodule LanguageTranslator.Translator do
  require Logger

  alias LanguageTranslator.Tasks.TranslateTask
  alias LanguageTranslator.Models.Analysis
  alias LanguageTranslator.DynamicSupervisor, as: DS

  def async_translate(%Analysis{} = analysis) do
    if Application.get_env(:language_translator, :env) == :test do
      {:ok, nil}
    else
      DynamicSupervisor.start_child(DS, {TranslateTask, analysis})
    end
  end
end
