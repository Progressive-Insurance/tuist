defmodule TuistTestSupport.Fixtures.RunsFixtures do
  @moduledoc """
  Fixtures for runs.
  """
  alias Tuist.Runs

  def build_fixture(attrs \\ []) do
    project_id =
      Keyword.get_lazy(attrs, :project_id, fn ->
        TuistTestSupport.Fixtures.ProjectsFixtures.project_fixture().id
      end)

    account_id =
      Keyword.get_lazy(attrs, :user_id, fn ->
        TuistTestSupport.Fixtures.AccountsFixtures.user_fixture(preload: [:account]).account.id
      end)

    Runs.create_build(%{
      id: Keyword.get(attrs, :id, UUIDv7.generate()),
      duration: Keyword.get(attrs, :duration, 1000),
      macos_version: Keyword.get(attrs, :macos_version, "11.2.3"),
      xcode_version: Keyword.get(attrs, :xcode_version, "12.4"),
      is_ci: Keyword.get(attrs, :is_ci, false),
      model_identifier: Keyword.get(attrs, :model_identifier, "Mac15,6"),
      scheme: Keyword.get(attrs, :scheme, "App"),
      project_id: project_id,
      account_id: account_id,
      inserted_at: Keyword.get(attrs, :inserted_at),
      status: Keyword.get(attrs, :status, :success),
      category: Keyword.get(attrs, :category, :incremental),
      git_commit_sha: Keyword.get(attrs, :git_commit_sha),
      git_branch: Keyword.get(attrs, :git_branch),
      git_ref: Keyword.get(attrs, :git_ref),
      issues: Keyword.get(attrs, :issues, []),
      files: Keyword.get(attrs, :files, []),
      targets: Keyword.get(attrs, :targets, [])
    })
  end
end
