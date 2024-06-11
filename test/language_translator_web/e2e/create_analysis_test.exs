defmodule LanguageTranslatorWeb.E2e.CreateAnalysisTest do
  use LanguageTranslatorWeb.ConnCase, async: false
  use Hound.Helpers

  alias LanguageTranslator.Accounts.UserToken
  alias LanguageTranslator.Repo

  hound_session()

  setup do
    Ecto.Adapters.SQL.Sandbox.mode(LanguageTranslator.Repo, {:shared, self()})
  end

  @tag :e2e
  test "user can create account and login" do
    navigate_to("localhost:4003/")
    assert page_title() =~ "Listing Analysis"

    click({:link_text, "Register"})
    assert page_title() =~ "Register"

    fill_field({:name, "user[email]"}, "e2e_test@gmail.com")
    fill_field({:name, "user[username]"}, "e2e_test")
    fill_field({:name, "user[password]"}, "ZdravaParola@123")
    click({:id, "user_main_language_code_live_select_component"})

    send_text("English")

    find_element(:id, "user_main_language_code_live_select_component")
    |> find_within_element(:tag, "li")
    |> click()

    click({:id, "register"})

    assert page_source() =~
             "Please check your email to confirm your account in order to be able to create analyses."

    click({:class, "hero-x-mark-solid"})

    click({:link_text, "New Analysis"})

    assert visible_page_text() =~
             "You must confirm your email before creating an analysis."

    click({:class, "hero-x-mark-solid"})

    user =
      Repo.get_by(LanguageTranslator.Accounts.User, username: "e2e_test")

    {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
    Repo.insert!(user_token)

    url = url(~p"/users/confirm/#{encoded_token}")
    navigate_to(url)

    assert page_title() =~ "Account Confirmation"
    click({:id, "confirm_account"})

    assert visible_page_text() =~ "User confirmed successfully."
    assert page_title() =~ "Listing Analysis"
    click({:class, "hero-x-mark-solid"})

    click({:link_text, "Log out"})
    click({:class, "hero-x-mark-solid"})

    click({:link_text, "Log in"})
    assert page_title() =~ "Login"
    fill_field({:name, "user[username]"}, "e2e_test")
    fill_field({:name, "user[password]"}, "ZdravaParola@123")
    click({:id, "login"})

    assert page_title() =~ "Listing Analysis"

    click({:link_text, "New Analysis"})
    assert page_title() =~ "New Analysis"

    fill_field({:id, "form_description"}, "Test analysis")
    click({:id, "is_public"})
    click({:id, "is_file"})

    fill_field({:id, "words_area"}, "words, for, test")
    click({:id, "form_save"})

    assert page_title() =~ "Listing Analysis"
    assert visible_page_text() =~ "Analysis created successfully"
    click({:class, "hero-x-mark-solid"})
    assert visible_page_text() =~ "Test analysis"
  end
end
