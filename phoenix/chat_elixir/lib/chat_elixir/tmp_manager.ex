defmodule ChatElixir.TmpManager do
  @moduledoc """
  This module is responsible for managing the tmp directory.
  """
  use GenServer

  # 10 seconds
  @every 10 * 1000
  @tmp_path "tmp/"
  @lifetime_in_hours 1

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  Write content to a file in the tmp directory.
  """
  @spec write(String.t(), iodata()) :: :ok
  def write(file_path, content) do
    GenServer.cast(__MODULE__, {:write, file_path, content})
  end

  @impl true
  def init(state) do
    state =
      [lifetime_in_hours: @lifetime_in_hours, max_files: nil, tmp_path: @tmp_path]
      |> Keyword.merge(state)
      |> Keyword.put(:tmp_path, "/" <> String.trim(state[:tmp_path], "/") <> "/")

    # Schedule work to be performed on start
    schedule_work()

    {:ok, state}
  end

  @impl true
  def handle_cast({:write, file_path, content}, state) do
    File.write!(state[:tmp_path] <> file_path, content)
    {:noreply, state}
  end

  @impl true
  def handle_info(:work, state) do
    NaiveDateTime.utc_now()
    {{2017, 11, 26}, {17, 49, 16}} |> NaiveDateTime.from_erl!()

    File.ls!(state[:tmp_path])
    |> Enum.map(fn file ->
      date =
        File.stat!(state[:tmp_path] <> file).ctime
        |> NaiveDateTime.from_erl!()

      {file, date}
    end)
    |> Enum.sort(fn {_, date1}, {_, date2} -> date1 > date2 end)
    |> Enum.with_index()
    |> Enum.each(fn {{name, date}, index} ->
      diff = NaiveDateTime.utc_now() |> NaiveDateTime.diff(date, :hour)
      !state[:max_files] || index + 1 <= state[:max_files] || File.rm!(state[:tmp_path] <> name)
      diff <= state[:lifetime_in_hours] || File.rm!(state[:tmp_path] <> name)
    end)

    # Reschedule once more
    schedule_work()
    {:noreply, state}
  end

  defp schedule_work do
    Process.send_after(self(), :work, @every)
  end
end
