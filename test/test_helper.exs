alias Ecto.Adapters.SQL.Sandbox
alias LanguageTranslator.Repo

Sandbox.mode(Repo, :manual)
{:ok, _} = Application.ensure_all_started(:language_translator)

pid = Sandbox.start_owner!(Repo)

Sandbox.allow(Repo, pid, LanguageTranslator.Translator.Supervisor)
Application.ensure_all_started(:hound)
ExUnit.start()
