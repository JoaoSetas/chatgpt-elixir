defmodule ChatElixir.ChatGPT.Api do

  def completion(text, options \\ %{}) do
    url = "https://api.openai.com/v1/completions"
    headers = [
      {"Authorization", "Bearer #{System.get_env("OPENAI_API_KEY")}"},
      {"Content-Type", "application/json"}
    ]
    options = %{
      "prompt" => text,
      "model" => "text-davinci-003",
      "max_tokens" => 3500,
      "temperature" => 0,
      "top_p" => 1,
      "frequency_penalty" => 0,
      "presence_penalty" => 0
    }
    |> Map.merge(options)

    body = Jason.encode!(options)
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} = HTTPoison.post(url, body, headers, [timeout: 100_000, recv_timeout: 100_000])

    %{"choices" => [%{"text" => response}|_]} = Jason.decode!(body)

    response
  end

  def completion_html(text, starting_code \\ "<", options \\ %{}) do
    prompt = "Using html and css. #{text}\n#{starting_code}"

    starting_code <> completion(text, Map.put(options, "prompt", prompt))
  end

  def image(text, options \\ %{}) do
    url = "https://api.openai.com/v1/images/generations"
    headers = [
      {"Authorization", "Bearer #{System.get_env("OPENAI_API_KEY")}"},
      {"Content-Type", "application/json"}
    ]
    default_options = %{
      "prompt" => text,
      "n" => 1,
      "size" => "512x512"
    }

    options = Map.merge(default_options, options)

    body = Jason.encode!(options)
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} = HTTPoison.post(url, body, headers, [timeout: 100_000, recv_timeout: 100_000])

    %{"data" => [%{"url" => response}|_]} = Jason.decode!(body)

    response
  end

end
