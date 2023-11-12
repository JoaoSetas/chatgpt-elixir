defmodule ChatElixir.ChatGPT.Api do
  @moduledoc """
  This module is responsible for interacting with the OpenAI API.
  """

  @type model :: :"gpt-4-vision-preview" | :"gpt-4-1106-preview" | :"gpt-3.5-turbo-1106"

  @doc """
  Completes chat from given `messages`

  Returns the completion as a string.
  """
  @spec chat_completion(list(), model, map()) ::
          {:ok, String.t()} | {:error, HTTPoison.Error} | {:error, String.t()}
  def chat_completion(messages, model \\ :"gpt-4-1106-preview", options \\ %{}) do
    url = "https://api.openai.com/v1/chat/completions"

    options = Map.put(options, "messages", messages)

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.post(url, get_body(model, options), get_headers(),
             timeout: 200_000,
            recv_timeout: 200_000
           ),
         %{"choices" => [%{"message" => %{"content" => content}} | _]} <- Jason.decode!(body) do
      {:ok, content}
    else
      {:error, %HTTPoison.Error{} = error} ->
        {:error, error}

      {:ok, %HTTPoison.Response{body: body}} ->
        %{"error" => %{"message" => message}} = Jason.decode!(body)
        {:error, message}
    end
  end

  @doc """
  Completes chat from given `messages`.

  This function is the same as `chat_completion/3` but returns a stream
  """
  @spec stream_chat_completion(list(), model, map()) :: Enumerable.t()
  def stream_chat_completion(messages, model \\ :"gpt-4-1106-preview", options \\ %{}) do
    url = "https://api.openai.com/v1/chat/completions"

    body =
      get_body(
        model,
        Map.merge(options, %{
          "stream" => true,
          "messages" => messages
        })
      )

    Stream.resource(
      fn ->
        HTTPoison.post!(url, body, get_headers(),
          stream_to: self(),
          async: :once,
          timeout: 200_000,
          recv_timeout: 200_000
        )
      end,
      &handle_async_response/1,
      &close_async_response/1
    )
  end

  @doc """
  Generates a image from the given `text`

  Returns a link as string
  """
  @spec image(String.t(), map()) ::
          {:ok, String.t()} | {:error, HTTPoison.Error} | {:error, String.t()}
  def image(text, options \\ %{}) do
    url = "https://api.openai.com/v1/images/generations"

    default_options = %{
      "model" => "dall-e-3",
      "prompt" => remove_grouped_spaces(text),
      "n" => 1,
      "size" => "1024x1024",
      "style" => "natural"
    }

    body = default_options |> Map.merge(options) |> Jason.encode!()

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.post(url, body, get_headers(), timeout: 20_000, recv_timeout: 20_000),
         %{"data" => [%{"url" => response} | _]} <- Jason.decode!(body) do
      {:ok, response}
    else
      {:error, %HTTPoison.Error{} = error} ->
        {:error, error}

      {:ok, %HTTPoison.Response{body: body}} ->
        %{"error" => %{"message" => message}} = Jason.decode!(body)
        {:error, message}
    end
  end

  @doc """
  Returns a list of embeddings for the given text.
  """
  @spec embeddings(String.t(), map()) :: [number()] | {:error, HTTPoison.Error}
  def embeddings(text, options \\ %{}) do
    url = "https://api.openai.com/v1/embeddings"

    default_options = %{
      "input" => remove_grouped_spaces(text),
      "model" => "text-embedding-ada-002"
    }

    body = default_options |> Map.merge(options) |> Jason.encode!()

    {:ok, %HTTPoison.Response{status_code: 200, body: body}} =
      HTTPoison.post(url, body, get_headers(), timeout: 60_000, recv_timeout: 60_000)

    %{"data" => [%{"embedding" => embeddings} | _]} = Jason.decode!(body)

    embeddings
  end

  defp close_async_response(resp) do
    :hackney.stop_async(resp)
  end

  defp handle_async_response({:done, resp}) do
    {:halt, resp}
  end

  defp handle_async_response(%HTTPoison.AsyncResponse{id: id} = resp) do
    receive do
      %HTTPoison.AsyncStatus{id: ^id} ->
        HTTPoison.stream_next(resp)
        {[], resp}

      %HTTPoison.AsyncHeaders{id: ^id} ->
        HTTPoison.stream_next(resp)
        {[], resp}

      %HTTPoison.AsyncChunk{id: ^id, chunk: chunk} ->
        HTTPoison.stream_next(resp)
        parse_chunk(chunk, resp)

      %HTTPoison.AsyncEnd{id: ^id} ->
        {:halt, resp}
    end
  end

  defp parse_chunk(chunk, resp) do
    chunk
    |> String.replace("data: ", "")
    |> String.split("\n\n", trim: true)
    |> Enum.map(&Jason.decode/1)
    |> Enum.reduce({[""], resp}, fn chunk, acc ->
      {[new_text], resp} = handle_chunk(chunk, resp)
      {[text], _} = acc
      {[text <> new_text], resp}
    end)
  end

  defp handle_chunk({:ok, %{"choices" => [%{"text" => text}]}}, resp) do
    {[text], resp}
  end

  defp handle_chunk({:ok, %{"choices" => [%{"delta" => %{"content" => text}}]}}, resp) do
    {[text], resp}
  end

  defp handle_chunk(_, resp) do
    {[""], {:done, resp}}
  end

  defp get_body(model, options) do
    %{
      "model" => model,
      "max_tokens" => 1000,
      "temperature" => 0,
      "top_p" => 1,
      "frequency_penalty" => 0,
      "presence_penalty" => 0
    }
    |> Map.merge(options)
    |> Jason.encode!()
  end

  defp get_headers() do
    [
      {"Authorization", "Bearer #{System.get_env("OPENAI_API_KEY")}"},
      {"Content-Type", "application/json"}
    ]
  end

  defp remove_grouped_spaces(text) do
    Regex.replace(~r/\s{2,}/, text, " ")
    |> String.trim()
  end
end
