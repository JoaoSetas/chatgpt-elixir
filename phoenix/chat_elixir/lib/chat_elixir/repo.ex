defmodule ChatElixir.Repo do
  use Ecto.Repo,
    otp_app: :chat_elixir,
    adapter: Ecto.Adapters.Postgres
end
