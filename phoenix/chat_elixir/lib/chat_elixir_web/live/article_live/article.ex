defmodule ChatElixirWeb.ArticleLive.Article do
  use ChatElixirWeb, :live_view

  alias ChatElixir.ChatGPT.Api

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     default_assign(socket,
       model: params["model"],
       question: params["question"],
       type: params["type"],
       code: params["code"]
     )}
  end

  @impl true
  def handle_event(
        "search",
        %{"question" => question, "type" => type, "code" => code, "model" => model},
        socket
      ) do
    target = self()

    Task.start(fn ->
      case Api.image("Simple photo about " <> question) do
        {:ok, image} ->
          send(target, {:render_image, image})

        {:error, error} ->
          send(target, {:render_error, error})
      end
    end)

    new_type = if String.first(type) == nil, do: "Article", else: type

    {:noreply,
     default_assign(socket,
       model: model,
       question: question,
       type: type,
       code: code,
       state: %{"disabled" => "true"},
       response_task: stream_response(new_type, question, code, model)
     )
     |> push_event("streaming_started", %{})
     |> push_patch(
       to: "/?" <> URI.encode_query(%{model: model, type: type, question: question, code: code})
     )}
  end

  def handle_event("search", %{}, socket) do
    {:noreply, socket}
  end

  def handle_event("show_html", _value, socket) do
    {:noreply, assign(socket, show_html: !socket.assigns.show_html)}
  end

  defp stream_response(type, question, code, model) do
    target = self()

    with_code = if String.first(code) == nil, do: "", else: ". For this"

    Task.Supervisor.async(StreamingText.TaskSupervisor, fn ->
      prompt =
        "Only responde with html. #{type} about #{question}#{with_code}:\n#{code}\n<div class=\"container\">"

      stream = Api.stream_chat_completion(prompt, model)

      for chunk <- stream, into: <<>> do
        send(target, {:render_response_chunk, chunk})
        chunk
      end
    end)
  end

  @impl true
  def handle_params(_params, _value, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:render_response_chunk, chunk}, socket) do
    stream = socket.assigns.stream <> chunk

    {:noreply,
     assign(socket, stream: stream)
     |> push_event("streaming", %{})}
  end

  def handle_info({ref, _content}, socket) when socket.assigns.response_task.ref == ref do
    {:noreply,
     assign(socket, state: %{})
     |> push_event("streaming_finished", %{})}
  end

  def handle_info({:render_image, image}, socket) do
    {:noreply, assign(socket, image: image)}
  end

  def handle_info({:render_error, error}, socket) do
    {:noreply, socket |> put_flash(:error, error)}
  end

  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  defp default_assign(socket, assigns) do
    assigns =
      %{
        model: "gpt-4",
        question: nil,
        type: nil,
        code: nil,
        state: %{},
        stream: "",
        image: "",
        show_html: false
      }
      |> Map.merge(Enum.into(assigns, %{}))

    assign(socket, assigns)
  end
end
