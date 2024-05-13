alias Ecto.Adapters.SQL.Sandbox
alias LanguageTranslator.Repo

Sandbox.mode(Repo, :manual)

pid = Sandbox.start_owner!(Repo, shared: false)
Sandbox.allow(Repo, pid, LanguageTranslator.Translator.Supervisor)
Sandbox.allow(Repo, pid, LanguageTranslator.Translator.Aggregator)

ExUnit.start()
Faker.start()
