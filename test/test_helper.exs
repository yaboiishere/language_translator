alias Ecto.Adapters.SQL.Sandbox
alias LanguageTranslator.Repo

Sandbox.mode(Repo, :manual)
{:ok, _} = Application.ensure_all_started(:language_translator)

pid = Sandbox.start_owner!(Repo)

analysis_monitor_pid = Process.whereis(LanguageTranslator.Translator.AnalysisMonitor)
Sandbox.allow(Repo, pid, LanguageTranslator.Translator.Supervisor)
Sandbox.allow(Repo, pid, analysis_monitor_pid)
Sandbox.allow(Repo, pid, LanguageTranslator.Translator.Refresher)

ExUnit.start()
