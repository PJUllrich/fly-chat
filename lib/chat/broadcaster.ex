defmodule Chat.Broadcaster do
  use GenServer

  @broadcast_interval :timer.seconds(1)

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    schedule_broadcast()
    {:ok, 0}
  end

  @impl true
  def handle_info(:broadcast, count) do
    schedule_broadcast()
    message = %{id: count, body: "message - #{count}"}
    Phoenix.PubSub.local_broadcast(Chat.PubSub, "chat", {:message, message})
    {:noreply, count + 1}
  end

  defp schedule_broadcast() do
    Process.send_after(self(), :broadcast, @broadcast_interval)
  end
end
