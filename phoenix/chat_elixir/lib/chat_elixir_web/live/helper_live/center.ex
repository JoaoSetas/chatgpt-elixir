defmodule ChatElixirWeb.HelperLive.Center do
  use ChatElixirWeb, :live_view

  alias ChatElixir.ChatGPT.Api

  @impl true
  def mount(params, _session, socket) do
    assigns =
      %{
        question: nil,
        description: nil,
        state: %{},
        image: nil,
        stream: "",
        messages: [],
        uploaded_files: [],
        show_html: false,
      }
      |> Map.merge(%{
        question: params["question"],
        description: params["description"]
      })

    {:ok,
     assign(socket, assigns)
     |> allow_upload(:images, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"question" => question}, socket) do
    {:noreply, assign(socket, question: question)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("show_html", _value, socket) do
    {:noreply, assign(socket, show_html: !socket.assigns.show_html)}
  end

  @impl true
  def handle_event(
        "search",
        %{"question" => question, "description" => description},
        socket
      ) do

    {uploaded_file, image} =
    consume_uploaded_entries(socket, :images, fn %{path: path}, entry ->
      dest = Path.join([:code.priv_dir(:chat_elixir), "static", "uploads", Path.basename(path)])
      # The `static/uploads` directory must exist for `File.cp!/2`
      # and MyAppWeb.static_paths/0 should contain uploads to work,.
      File.cp!(path, dest)
      {:ok, {entry.client_type, ~p"/uploads/#{Path.basename(dest)}"}}
    end)
    |>  handle_image(socket)

    messages = format_message(question, description, image)

    {:noreply,
     assign(socket,
       question: question,
       description: description,
       state: %{"disabled" => "true"},
       stream: "",
       messages: messages,
       show_html: false,
       image: (if uploaded_file, do: Routes.static_url(socket, uploaded_file), else: nil),
       response_task: stream_response(messages),
       uploaded_files: &(&1 ++ [uploaded_file])
     )
     |> push_event("streaming_started", %{})
     |> push_patch(
       to: "/helper?" <> URI.encode_query(%{question: question, description: description})
     )}
  end

  def handle_event("page", %{"page" => page}, socket) do
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
       show_html: false,
       response_task: stream_response(messages)
     )
     |> push_event("streaming_started", %{})}
  end

  @impl true
  def handle_info({:render_response_chunk, chunk}, socket) do
    stream = socket.assigns.stream <> chunk

    {:noreply,
     assign(socket, stream: stream)
     |> push_event("streaming", %{})}
  end

  @impl true
  def handle_info({ref, content}, socket) when socket.assigns.response_task.ref == ref do
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

  @impl true
  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _value, socket) do
    {:noreply, socket}
  end

  defp stream_response(messages) do
    target = self()

    Task.Supervisor.async(StreamingText.TaskSupervisor, fn ->
      stream = Api.stream_chat_completion(messages, :"gpt-4-vision-preview")

      for chunk <- stream, into: <<>> do
        send(target, {:render_response_chunk, chunk})
        chunk
      end
    end)
  end

  defp format_message(question, description, nil) do
    with_code =
      if String.first(description) == nil, do: "", else: ". More information about the website:\n"

    [
      system_role(),
      %{
        "role" => "user",
        "content" => [
          %{
            "type" => "text",
            "text" => "#{question}#{with_code}#{description}"
          }
        ]
      }
    ]
  end

  defp format_message(question, description, image) do
    [system, %{"content" => content} = user]  = format_message(question, description, nil)
    content = content ++
    [
      %{
      "type" => "image_url",
      "image_url" => %{
        "url" => image,
        "detail" => "low"
      }
    }]
    [system, %{user | "content" => content}]
  end

  def handle_image([{type, uploaded_file}], socket) do
    image = Routes.static_url(socket, uploaded_file)
    image =  [:code.priv_dir(:chat_elixir), "static", "uploads", Path.basename(uploaded_file)]
    |> Path.join()
    |> File.read!()
    |> Base.encode64()
    {uploaded_file, "data:#{type};base64,#{image}"}
  end

  def handle_image([], _socket), do: {nil, nil}

  defp system_role() do
    %{
      "role" => "system",
      "content" => """
      You are a web designer.
      Design a complete website based on the user issue.
      The user can give a image about the issue.
      Output the page content to help the user indentify problems.
      Add links between the content for more information.
      At the end add navigation links, that must be inside a nav tag at the end of the page.
      Any link must contain a html attribute in this format `phx-click="page" phx-value-page="page_name_value"`.
      The return must be the html content inside this `<div class=\"container\">`.
      Only output HTML without ```html at the beginning.
      No images.
      No forms.
      No HTML comments.
      """
    }
  end

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  def error_to_string(:too_many_files), do: "You have selected too many files"
end
