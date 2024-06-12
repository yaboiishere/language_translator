defmodule LanguageTranslatorWeb.E2e.UserCreateAccountAndLoginTest do
  use LanguageTranslatorWeb.IntegrationCase

  alias LanguageTranslator.Repo
  alias LanguageTranslator.Accounts.UserToken

  hound_session()

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

    click({:link_text, "Log out"})

    click({:class, "hero-x-mark-solid"})

    click({:link_text, "Log in"})

    assert page_title() =~ "Login"

    fill_field({:name, "user[username]"}, "e2e_test")
    fill_field({:name, "user[password]"}, "ZdravaParola@123")
    click({:id, "login"})

    assert page_title() =~ "Listing Analysis"
    assert visible_page_text() =~ "Welcome back!"
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
    assert visible_page_text() =~ "Logged out successfully."
    click({:class, "hero-x-mark-solid"})
    assert page_title() =~ "Listing Analysis"

    click({:link_text, "Log in"})
    assert page_title() =~ "Login"

    fill_field({:name, "user[username]"}, "e2e_test_non_existant")
    fill_field({:name, "user[password]"}, "ZdravaParola@123")
    click({:id, "login"})

    assert page_title() =~ "Login"
    assert visible_page_text() =~ "Invalid username or password"
  end
end
