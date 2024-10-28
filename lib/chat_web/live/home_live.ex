defmodule ChatWeb.HomeLive do
  use ChatWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex justify-center w-full space-x-2 pb-2">
        <.link navigate={~p"/?#{[region: :dfw, priority: 0]}"} class="btn">Chat DFW - P0</.link>
        <.link navigate={~p"/?#{[region: :dfw, priority: 1]}"} class="btn">Chat DFW - P1</.link>
        <.link navigate={~p"/?#{[region: :ams, priority: 1]}"} class="btn">Chat AMS - P1</.link>
      </div>
      <ul id="chat" phx-update="stream" class="rounded-md p-3 border border-gray-300 h-full">
        <li :for={{dom_id, message} <- @streams.messages} id={dom_id}>
          <%= message.body %>
        </li>
      </ul>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Chat.PubSub, "chat")
    end

    {:ok, stream(socket, :messages, [])}
  end

  @impl true
  def handle_info({:message, message}, socket) do
    {:noreply, stream_insert(socket, :messages, message, at: 0)}
  end
end
