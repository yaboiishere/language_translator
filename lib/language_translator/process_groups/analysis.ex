defmodule LanguageTranslator.ProcessGroups.Analysis do
  @group_name :analysis

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

  def update_analysis(analysis) do
    broadcast({:update_analysis, analysis})
  end

  def count_members() do
    @group_name
    |> :pg.get_members()
    |> length()
  end
end
