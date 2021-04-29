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
    {_format_output, 0} = System.cmd("mix", ["format"] ++ staged_files([".ex", ".exs"]))
    {_add_output, 0} = System.cmd("git", ["add"] ++ staged_files())
    {:ok, "SUCCESS!"}
  end
end
