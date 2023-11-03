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
    # target = self()

    # Task.start(fn ->
    #   case Api.image("Simple photo without text about " <> question) do
    #     {:ok, image} ->
    #       send(target, {:render_image, image})

    #     {:error, error} ->
    #       send(target, {:render_error, error})
    #   end
    # end)

    messages = format_message(type, question, code)

    {:noreply,
     default_assign(socket,
       model: model,
       question: question,
       type: type,
       code: code,
       state: %{"disabled" => "true"},
       messages: messages,
       response_task: stream_response(model, messages)
     )
     |> push_event("streaming_started", %{})
     |> push_patch(
       to: "/?" <> URI.encode_query(%{model: model, type: type, question: question, code: code})
     )}
  end

  def handle_event("show_html", _value, socket) do
    {:noreply, assign(socket, show_html: !socket.assigns.show_html)}
  end

  def handle_event("page", %{"page" => page}, socket) do
    # target = self()

    # Task.start(fn ->
    #   case Api.image("Simple photo without text about " <> page) do
    #     {:ok, image} ->
    #       send(target, {:render_image, image})

    #     {:error, error} ->
    #       send(target, {:render_error, error})
    #   end
    # end)

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
       response_task: stream_response(socket.assigns.model, messages)
     )
     |> push_event("streaming_started", %{})}
  end

  defp stream_response(model, messages) do
    target = self()

    Task.Supervisor.async(StreamingText.TaskSupervisor, fn ->
      stream = Api.stream_chat_completion(messages, model)

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
        model: "gpt-4",
        question: nil,
        type: nil,
        code: nil,
        state: %{},
        stream: "",
        image: "",
        show_html: false,
        messages: []
      }
      |> Map.merge(Enum.into(assigns, %{}))

    assign(socket, assigns)
  end

  defp format_message("website", question, code) do
    with_code =
      if String.first(code) == nil, do: "", else: ". More information about the website:\n"

    [
      system_role(),
      %{
        "role" => "user",
        "content" => "#{question}#{with_code}#{code}"
      }
    ]
  end

  defp format_message(type, question, code) do
    type = if String.first(type) == nil, do: "Article", else: type
    with_code = if String.first(code) == nil, do: "", else: ". For this"

    [
      %{
        "role" => "user",
        "content" =>
          "Only responde with html. #{type} about #{question}#{with_code}:\n#{code}\n<div class=\"container\">"
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
