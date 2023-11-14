defmodule ChatElixirWeb.ArticleLive.Article do
  use ChatElixirWeb, :live_view

  alias ChatElixir.ChatGPT.Api

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     default_assign(socket,
       question: params["question"],
       description: params["description"]
     )}
  end

  @impl true
  def handle_event(
        "search",
        %{"question" => question, "description" => description},
        socket
      ) do
    target = self()

    Task.start(fn ->
      case Api.image("Simple photo without text about " <> question) do
        {:ok, image} ->
          send(target, {:render_image, image})

        {:error, error} ->
          send(target, {:render_error, error})
      end
    end)

    messages = format_message(question, description)

    {:noreply,
     default_assign(socket,
       question: question,
       description: description,
       state: %{"disabled" => "true"},
       messages: messages,
       response_task: stream_response(messages)
     )
     |> push_event("streaming_started", %{})
     |> push_event("page-loading-start", %{})
     |> push_patch(
       to: "/article?" <> URI.encode_query(%{question: question, description: description})
     )}
  end

  def handle_event("show_html", _value, socket) do
    {:noreply, assign(socket, show_html: !socket.assigns.show_html)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("page", %{"page" => page}, socket) do
    target = self()

    Task.start(fn ->
      case Api.image("Simple photo without text about " <> page) do
        {:ok, image} ->
          send(target, {:render_image, image})

        {:error, error} ->
          send(target, {:render_error, error})
      end
    end)

    Task.shutdown(socket.assigns.response_task)

    messages =
      socket.assigns.messages ++
        [
          %{
            "role" => "user",
            "content" => "User selected page #{page}"
          }
        ]

    {:noreply,
     assign(socket,
       state: %{"disabled" => "true"},
       stream: "",
       image: "",
       show_html: false,
       response_task: stream_response(messages)
     )
     |> push_event("streaming_started", %{})
     |> push_event("page-loading-start", %{})}
  end

  defp stream_response(messages) do
    target = self()

    Task.Supervisor.async(StreamingText.TaskSupervisor, fn ->
      stream = Api.stream_chat_completion(messages, :"gpt-4-1106-preview")

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
     |> push_event("streaming", %{})
     |> push_event("page-loading-stop", %{})}
  end

  def handle_info({ref, content}, socket) when socket.assigns.response_task.ref == ref do
    # List.delete_at(socket.assigns.messages, 2)
    # |> List.delete_at(3)
    messages =
      socket.assigns.messages ++
        [
          %{
            "role" => "assistant",
            "content" => content
          }
        ]

    {:noreply,
     assign(socket, state: %{}, messages: messages)
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
        question: nil,
        description: nil,
        state: %{},
        stream: "",
        image: "",
        show_html: false,
        messages: []
      }
      |> Map.merge(Enum.into(assigns, %{}))

    assign(socket, assigns)
  end

  defp format_message(question, description) do
    with_description =
      if String.first(description) == nil, do: "", else: ". More information about the website:\n"

    [
      system_role(),
      %{
        "role" => "user",
        "content" => "#{question}#{with_description}#{description}"
      }
    ]
  end

  defp system_role() do
    %{
      "role" => "system",
      "content" => """
      You are a web developer.
      Design a complete website based on the user topic.
      Output page content.
      Add links between the content for more information.
      At the end add navigation links, that must be inside a nav tag at the end of the page.
      Any link must contain a html attribute in this format `phx-click="page" phx-value-page="page_name_value"`.
      The return must be the html content inside this `<div class=\"container\">`.
      Only output HTML without ```html at the beginning.
      No images.
      No HTML comments.
      """
    }
  end
end
