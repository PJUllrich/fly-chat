defmodule ChatWeb.HomeLive do
  use ChatWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <header class="flex justify-center space-x-4 py-2 border-b border-gray-300">
        <ul class="flex space-x-4">
          <li>
            <span class="font-semibold">region:</span> <%= Application.get_env(:chat, :fly_region) %>
          </li>
          <%!-- <li>
            <span class="font-semibold">process group:</span> <%= Application.get_env(
              :chat,
              :fly_process_group
            ) %>
          </li> --%>
          <li>
            <span class="font-semibold">machine id:</span> <%= Application.get_env(
              :chat,
              :fly_machine_id
            ) %>
          </li>
          <li>
            <span class="font-semibold">memory:</span> <%= Application.get_env(
              :chat,
              :fly_vm_memory_mb
            ) %>
          </li>
        </ul>
      </header>
      <div class="mt-12 max-w-2xl mx-auto">
        <div class="flex justify-center w-full space-x-2 pb-2">
          <.link
            :for={{creator_id, machine_id} <- @creators}
            href={~p"/?#{[instance: machine_id]}"}
            class={["btn", @creator_id == creator_id && "bg-green-600 text-white"]}
          >
            Stream: <%= creator_id %>
          </.link>
        </div>
        <ul id="chat" phx-update="stream" class="rounded-md p-3 border border-gray-300 h-full">
          <li :for={{dom_id, message} <- @streams.messages} id={dom_id}>
            <%= @creator_id %>: <%= message.body %>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Chat.PubSub, "chat")
    end

    state = Chat.Creators.get_state()
    creators = Enum.sort_by(state.creators, fn {key, _value} -> key end)

    {:ok,
     socket
     |> assign(creator_id: state.creator_id, creators: creators)
     |> stream(:messages, [])}
  end

  @impl true
  def handle_info({:message, message}, socket) do
    {:noreply, stream_insert(socket, :messages, message, at: 0)}
  end
end
