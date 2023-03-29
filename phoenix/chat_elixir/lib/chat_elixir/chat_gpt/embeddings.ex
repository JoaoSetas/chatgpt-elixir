defmodule ChatElixir.ChatGPT.Embeddings do

  alias ChatElixir.ChatGPT.Api

  def add_embeddings_to_file() do
    content = File.read!("lib/chat_elixir/chat_gpt/embeddings.json")
    |> Jason.decode!()
    |> generate_embeddings()
    |> Task.await_many(60_000)
    |> Jason.encode!()

    File.write!("lib/chat_elixir/chat_gpt/embeddings.json", content)
  end

  defp generate_embeddings([%{"embedding" => _ } = item | rest]) do
    [item | generate_embeddings(rest)]
  end

  defp generate_embeddings([item | rest]) do
    task = Task.async(fn ->
      Map.put(item, "embedding", Api.embeddings(item["name"]))
    end)
    [task | generate_embeddings(rest)]
  end

  defp generate_embeddings([]), do: []

  def search_simularity(text) do
    File.read!("lib/chat_elixir/chat_gpt/embeddings.json")
    |> Jason.decode!()
    |> calculate_cosine(text)
    |> Task.await_many(30_000)
    |> Enum.sort_by(& &1["score"], &>=/2)
    |> Enum.take(5)
  end

  defp calculate_cosine([%{"embedding" => embedding } = item | rest], text) do
    task = Task.async(fn ->
      item
      |> Map.put("score", Similarity.cosine(embedding, Api.embeddings(text)))
      |> Map.delete("embedding")
    end)

    [task | calculate_cosine(rest, text)]
  end

  defp calculate_cosine([], _text), do: []

end