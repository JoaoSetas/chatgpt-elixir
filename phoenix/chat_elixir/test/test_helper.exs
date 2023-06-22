ExUnit.start()

if !System.get_env("GITHUB_ACTIONS") do
  Ecto.Adapters.SQL.Sandbox.mode(ChatElixir.Repo, :manual)
end
