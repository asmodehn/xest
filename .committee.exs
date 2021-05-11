defmodule YourApp.Commit do
  use Committee
  import Committee.Helpers, only: [staged_files: 0, staged_files: 1]

  # Here's where you can add your Git hooks!
  #
  # To abort a commit, return in the form of `{:halt, reason}`.
  # To print a success message, return in the form of `{:ok, message}`.

  @impl true
  @doc """
  This function auto-runs `mix format` on staged files.
  To test: `mix committee.runner [pre_commit | post_commit]`
  """
  def pre_commit do
    existing_staged_files = staged_files([".ex", ".exs"]) |> Enum.filter(&File.exists?(&1))

    {_format_output, 0} = System.cmd("mix", ["format"] ++ existing_staged_files)
    {_add_output, 0} = System.cmd("git", ["add"] ++ existing_staged_files)
    {:ok, "SUCCESS!"}
  end
end
