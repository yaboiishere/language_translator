defmodule LanguageTranslator.Translator.ProcessGroup do
  @group_name :translators

  def join(pid) do
    :pg.join(@group_name, pid)
  end

  def leave(pid) do
    :pg.leave(@group_name, pid)
  end

  def broadcast(message) do
    @group_name
    |> :pg.get_members()
    |> Enum.each(fn pid ->
      send(pid, message)
    end)
  end

  def translate(source_language, word, caller_ref) do
    @group_name
    |> :pg.get_members()
    |> Enum.map(fn pid ->
      send(pid, {:translate, source_language, word, caller_ref})
    end)
  end

  def count_members() do
    @group_name
    |> :pg.get_members()
    |> length()
  end
end
