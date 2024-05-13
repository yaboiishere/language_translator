alias LanguageTranslator.GoogleApi.Translate
alias LanguageTranslator.Models.Language
alias LanguageTranslator.Accounts.User
alias LanguageTranslator.Repo

english = %Language{code: "en", display_name: "English"}
bulgarian = %Language{code: "bg", display_name: "Bulgarian"}

Mix.ensure_application!(:wx)
Mix.ensure_application!(:runtime_tools)
Mix.ensure_application!(:observer)
# :observer.start()
