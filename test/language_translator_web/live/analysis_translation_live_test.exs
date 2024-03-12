defmodule LanguageTranslatorWeb.AnalysisTranslationLiveTest do
  use LanguageTranslatorWeb.ConnCase

  import Phoenix.LiveViewTest
  import LanguageTranslator.ModelsFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_analysis_translation(_) do
    analysis_translation = analysis_translation_fixture()
    %{analysis_translation: analysis_translation}
  end

  describe "Index" do
    setup [:create_analysis_translation]

    test "lists all analysis_translations", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/analysis_translations")

      assert html =~ "Listing Analysis translations"
    end

    test "saves new analysis_translation", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/analysis_translations")

      assert index_live |> element("a", "New Analysis translation") |> render_click() =~
               "New Analysis translation"

      assert_patch(index_live, ~p"/analysis_translations/new")

      assert index_live
             |> form("#analysis_translation-form", analysis_translation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#analysis_translation-form", analysis_translation: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/analysis_translations")

      html = render(index_live)
      assert html =~ "Analysis translation created successfully"
    end

    test "updates analysis_translation in listing", %{conn: conn, analysis_translation: analysis_translation} do
      {:ok, index_live, _html} = live(conn, ~p"/analysis_translations")

      assert index_live |> element("#analysis_translations-#{analysis_translation.id} a", "Edit") |> render_click() =~
               "Edit Analysis translation"

      assert_patch(index_live, ~p"/analysis_translations/#{analysis_translation}/edit")

      assert index_live
             |> form("#analysis_translation-form", analysis_translation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#analysis_translation-form", analysis_translation: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/analysis_translations")

      html = render(index_live)
      assert html =~ "Analysis translation updated successfully"
    end

    test "deletes analysis_translation in listing", %{conn: conn, analysis_translation: analysis_translation} do
      {:ok, index_live, _html} = live(conn, ~p"/analysis_translations")

      assert index_live |> element("#analysis_translations-#{analysis_translation.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#analysis_translations-#{analysis_translation.id}")
    end
  end

  describe "Show" do
    setup [:create_analysis_translation]

    test "displays analysis_translation", %{conn: conn, analysis_translation: analysis_translation} do
      {:ok, _show_live, html} = live(conn, ~p"/analysis_translations/#{analysis_translation}")

      assert html =~ "Show Analysis translation"
    end

    test "updates analysis_translation within modal", %{conn: conn, analysis_translation: analysis_translation} do
      {:ok, show_live, _html} = live(conn, ~p"/analysis_translations/#{analysis_translation}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Analysis translation"

      assert_patch(show_live, ~p"/analysis_translations/#{analysis_translation}/show/edit")

      assert show_live
             |> form("#analysis_translation-form", analysis_translation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#analysis_translation-form", analysis_translation: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/analysis_translations/#{analysis_translation}")

      html = render(show_live)
      assert html =~ "Analysis translation updated successfully"
    end
  end
end
