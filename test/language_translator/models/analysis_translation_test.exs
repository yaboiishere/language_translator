defmodule LanguageTranslator.Models.AnalysisTranslationTest do
  use LanguageTranslator.DataCase

  alias LanguageTranslator.Models.AnalysisTranslation

  test "valid changeset" do
    changeset =
      AnalysisTranslation.changeset(%AnalysisTranslation{}, %{analysis_id: 1, translation_id: 1})

    assert changeset.valid?
  end

  test "invalid changeset without analysis_id" do
    changeset = AnalysisTranslation.changeset(%AnalysisTranslation{}, %{translation_id: 1})
    refute changeset.valid?

    assert {:error, changeset.errors} ==
             {:error, [{:analysis_id, {"can't be blank", [validation: :required]}}]}
  end

  test "invalid changeset without translation_id" do
    changeset = AnalysisTranslation.changeset(%AnalysisTranslation{}, %{analysis_id: 1})
    refute changeset.valid?

    assert {:error, changeset.errors} ==
             {:error, [{:translation_id, {"can't be blank", [validation: :required]}}]}
  end
end
