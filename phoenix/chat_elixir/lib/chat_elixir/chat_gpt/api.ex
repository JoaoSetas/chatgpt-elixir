defmodule ChatElixir.ChatGPT.Api do

  def completion(text, options \\ %{}) do
    url = "https://api.openai.com/v1/completions"

    {:ok, %HTTPoison.Response{status_code: 200, body: body}} = HTTPoison.post(url, get_body(text, options), get_headers(), [timeout: 100_000, recv_timeout: 1_000])

    %{"choices" => [%{"text" => response}|_]} = Jason.decode!(body)

    response
  end

  def stream_completion(text, options \\ %{}) do
    url = "https://api.openai.com/v1/completions"
    body = get_body(text, Map.merge(options, %{"stream" => true}))

    Stream.resource(
      fn -> HTTPoison.post!(url, body, get_headers(), stream_to: self(), async: :once, timeout: 100_000, recv_timeout: 100_000) end,
      &handle_async_response/1,
      &close_async_response/1
    )
  end

  def completion_html(text, starting_code \\ "<", options \\ %{}) do
    prompt = "Using html. #{text}\n#{starting_code}"

    completion(text, Map.put(options, "prompt", prompt))
  end

  def stream_completion_html(text, starting_code \\ "<", options \\ %{}) do
    prompt = "Using html. #{text}\n#{starting_code}"

    stream_completion(text, Map.put(options, "prompt", prompt))
  end

  def image(text, options \\ %{}) do
    url = "https://api.openai.com/v1/images/generations"
    default_options = %{
      "prompt" => text,
      "n" => 1,
      "size" => "512x512"
    }

    options = Map.merge(default_options, options)

    body = Jason.encode!(options)
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} = HTTPoison.post(url, body, get_headers(), [timeout: 10_000, recv_timeout: 10_000])

    %{"data" => [%{"url" => response}|_]} = Jason.decode!(body)

    response
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
    {chunk, done?} =
      chunk
      |> String.split("data:")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.reduce({"", false}, fn trimmed, {chunk, is_done?} ->
        case Jason.decode(trimmed) do
          {:ok, %{"choices" => [%{"text" => text}]}} ->
            {chunk <> text, is_done? or false}

          {:error, %{data: "[DONE]"}} ->
            {chunk, is_done? or true}
        end
      end)

    if done? do
      {[chunk], {:done, resp}}
    else
      {[chunk], resp}
    end
  end

  def get_body(text, options \\ []) do
    %{
      "prompt" => text,
      "model" => "text-davinci-003",
      "max_tokens" => 2000,
      "temperature" => 0.2,
      "top_p" => 1,
      "frequency_penalty" => 0,
      "presence_penalty" => 0
    }
    |> Map.merge(options)
    |> Jason.encode!
  end

  def get_headers() do
    [
      {"Authorization", "Bearer #{System.get_env("OPENAI_API_KEY")}"},
      {"Content-Type", "application/json"}
    ]
  end

end
