defmodule ChatElixirWeb.AudioController do
  use ChatElixirWeb, :controller

  def create(conn, %{
        "audio" => %Plug.Upload{
          path: path
        }
      }) do
    dest =
      Path.join([
        :code.priv_dir(:chat_elixir),
        "static",
        "images",
        "uploads",
        Path.basename(path) <> ".ogg"
      ])

    File.cp!(path, dest)

    {:ok, text} = ChatElixir.ChatGPT.Api.speech_to_text(dest)

    conn
    |> put_status(:ok)
    |> json(%{text: text})
  rescue
    _ ->
      conn
      |> put_status(:bad_request)
      |> json(%{message: "Error uploading audio"})
  end
end
