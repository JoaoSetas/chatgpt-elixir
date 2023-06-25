defmodule ChatElixirWeb.ArticleLive.Article do
  use ChatElixirWeb, :live_view

  alias ChatElixir.ChatGPT

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     assign(socket,
       stream: "",
       question: params["question"],
       type: params["type"],
       code: params["code"],
       state: %{},
       params: %{"ola" => "adeus"},
       image: ""
     )}
  end

  @impl true
  def handle_event("search", %{"question" => question, "type" => type, "code" => code}, socket) do
    target = self()

    Task.start(fn ->
      case ChatGPT.Api.image("Simple photo about " <> question) do
        {:ok, image} ->
          send(target, {:render_image, image})

        {:error, error} ->
          send(target, {:render_error, error})
      end
    end)

    new_type = if String.first(type) == nil, do: "Article", else: type

    stream =
      ChatGPT.Api.stream_completion_html(
        new_type <> " about " <> question <> ":\n" <> code,
        "<div class=\"container\">"
      )

    {:noreply,
     assign(socket,
       question: question,
       type: type,
       code: code,
       state: %{"disabled" => "true"},
       stream: "",
       image: "",
       response_task: stream_response(stream)
     )
     |> push_event("streaming_started", %{})
     |> push_patch(to: "/?" <> URI.encode_query(%{type: type, question: question, code: code}))}
  end

  def handle_event("search", %{}, socket) do
    {:noreply,
     assign(socket,
       question: nil,
       type: nil,
       code: nil,
       state: %{},
       stream: "",
       image: ""
     )}
  end

  @impl true
  def handle_params(_params, _value, socket) do
    {:noreply, socket}
  end

  defp stream_response(stream) do
    target = self()

    Task.Supervisor.async(StreamingText.TaskSupervisor, fn ->
      for chunk <- stream, into: <<>> do
        send(target, {:render_response_chunk, chunk})
        chunk
      end
    end)
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
end
