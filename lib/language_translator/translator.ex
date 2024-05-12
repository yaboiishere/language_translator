defmodule LanguageTranslator.Translator do
  require Logger

  alias LanguageTranslator.Tasks.TranslateTask
  alias LanguageTranslator.Models.Analysis
  alias LanguageTranslator.DynamicSupervisor, as: DS

  def async_translate(%Analysis{} = analysis) do
    DynamicSupervisor.start_child(DS, {TranslateTask, analysis})
  end
end
