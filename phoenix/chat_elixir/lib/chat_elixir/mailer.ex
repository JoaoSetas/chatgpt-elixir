defmodule ChatElixir.Mailer do
  @moduledoc """
  This module is responsible for sending emails.
  """
  use Swoosh.Mailer, otp_app: :chat_elixir
end
