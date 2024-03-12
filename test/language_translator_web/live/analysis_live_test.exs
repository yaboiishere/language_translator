defmodule LanguageTranslatorWeb.AnalysisLiveTest do
  use LanguageTranslatorWeb.ConnCase

  import Phoenix.LiveViewTest
  import LanguageTranslator.ModelsFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_analysis(_) do
    analysis = analysis_fixture()
    %{analysis: analysis}
  end

  describe "Index" do
    setup [:create_analysis]

    test "lists all analysis", %{conn: conn, analysis: analysis} do
      {:ok, _index_live, html} = live(conn, ~p"/analysis")

      assert html =~ "Listing Analysis"
      assert html =~ analysis.name
    end

    test "saves new analysis", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/analysis")

      assert index_live |> element("a", "New Analysis") |> render_click() =~
               "New Analysis"

      assert_patch(index_live, ~p"/analysis/new")

      assert index_live
             |> form("#analysis-form", analysis: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#analysis-form", analysis: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/analysis")

      html = render(index_live)
      assert html =~ "Analysis created successfully"
      assert html =~ "some name"
    end

    test "updates analysis in listing", %{conn: conn, analysis: analysis} do
      {:ok, index_live, _html} = live(conn, ~p"/analysis")

      assert index_live |> element("#analysis-#{analysis.id} a", "Edit") |> render_click() =~
               "Edit Analysis"

      assert_patch(index_live, ~p"/analysis/#{analysis}/edit")

      assert index_live
             |> form("#analysis-form", analysis: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#analysis-form", analysis: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/analysis")

      html = render(index_live)
      assert html =~ "Analysis updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes analysis in listing", %{conn: conn, analysis: analysis} do
      {:ok, index_live, _html} = live(conn, ~p"/analysis")

      assert index_live |> element("#analysis-#{analysis.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#analysis-#{analysis.id}")
    end
  end

  describe "Show" do
    setup [:create_analysis]

    test "displays analysis", %{conn: conn, analysis: analysis} do
      {:ok, _show_live, html} = live(conn, ~p"/analysis/#{analysis}")

      assert html =~ "Show Analysis"
      assert html =~ analysis.name
    end

    test "updates analysis within modal", %{conn: conn, analysis: analysis} do
      {:ok, show_live, _html} = live(conn, ~p"/analysis/#{analysis}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Analysis"

      assert_patch(show_live, ~p"/analysis/#{analysis}/show/edit")

      assert show_live
             |> form("#analysis-form", analysis: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#analysis-form", analysis: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/analysis/#{analysis}")

      html = render(show_live)
      assert html =~ "Analysis updated successfully"
      assert html =~ "some updated name"
    end
  end
end
