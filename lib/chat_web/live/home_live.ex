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
          <li>
            <span class="font-semibold">process group:</span> <%= Application.get_env(
              :chat,
              :fly_process_group
            ) %>
          </li>
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
          <.link href={~p"/?#{[region: :dfw, priority: 0]}"} class="btn">Chat DFW - P0</.link>
          <.link href={~p"/?#{[region: :dfw, priority: 1]}"} class="btn">Chat DFW - P1</.link>
          <.link href={~p"/?#{[region: :ams, priority: 1]}"} class="btn">Chat AMS - P1</.link>
        </div>
        <ul id="chat" phx-update="stream" class="rounded-md p-3 border border-gray-300 h-full">
          <li :for={{dom_id, message} <- @streams.messages} id={dom_id}>
            <%= @region %>: <%= message.body %>
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

    region = Application.get_env(:chat, :fly_region)
    {:ok, socket |> assign(:region, region) |> stream(:messages, [])}
  end

  @impl true
  def handle_info({:message, message}, socket) do
    {:noreply, stream_insert(socket, :messages, message, at: 0)}
  end
end
