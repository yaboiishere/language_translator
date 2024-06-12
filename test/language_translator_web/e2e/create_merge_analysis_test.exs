defmodule LanguageTranslatorWeb.E2e.CreateMergeAnalysisTest do
  use LanguageTranslatorWeb.IntegrationCase

  alias LanguageTranslator.Accounts.UserToken
  alias LanguageTranslator.Models.Analysis
  alias LanguageTranslator.Repo

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

    first_analysis =
      Analysis.changeset(
        %Analysis{},
        %{
          description: "E2E Test Analysis 1",
          source_language_code: "en",
          user_id: user.id,
          source_words: ["Hello", "World"],
          status: :completed
        }
      )
      |> Repo.insert!()

    second_analysis =
      Analysis.changeset(
        %Analysis{},
        %{
          description: "E2E Test Analysis 2",
          source_language_code: "en",
          user_id: user.id,
          source_words: ["New", "World"],
          status: :completed
        }
      )
      |> Repo.insert!()

    click({:link_text, "Log out"})
    click({:class, "hero-x-mark-solid"})

    click({:link_text, "Log in"})
    assert page_title() =~ "Login"
    fill_field({:name, "user[username]"}, "e2e_test")
    fill_field({:name, "user[password]"}, "ZdravaParola@123")
    click({:id, "login"})

    assert page_title() =~ "Listing Analysis"

    assert visible_page_text() =~ "E2E Test Analysis 1"
    assert visible_page_text() =~ "E2E Test Analysis 2"

    :id
    |> find_element("analysis_#{first_analysis.id}")
    |> find_within_element(:tag, "td")
    |> move_to(1, 1)

    :id
    |> find_element("analysis_#{first_analysis.id}")
    |> find_within_element(:tag, "td")
    |> click()

    navigate_to(url(~p"/analysis/#{first_analysis.id}"))

    assert page_title() =~ "Show Analysis"

    click({:id, "extra_analysis"})

    :id
    |> find_element("extra_analysis")
    |> find_within_element(:tag, "li")
    |> click()

    click({:id, "save_merged_analysis"})

    :id
    |> find_element("form_description")
    |> inner_text() =~ "Merged analysis"

    :id
    |> find_element("words_area")
    |> inner_text() =~ "Hello,World,New"

    click({:id, "form_save"})
    click({:id, "form_save"})

    assert page_title() =~ "Listing Analysis"

    assert visible_page_text() =~ "Analysis created successfully"
    click({:class, "hero-x-mark-solid"})

    assert visible_page_text() =~ "Merged analysis (#{first_analysis.id}, #{second_analysis.id})"
  end
end
