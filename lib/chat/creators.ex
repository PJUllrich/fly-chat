defmodule Chat.Creators do
  use GenServer

  require Logger

  @topic "creators"

  # Public functions

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  # Callbacks

  @impl GenServer
  def init(_args) do
    creator_id = :crypto.strong_rand_bytes(4) |> Base.encode16()

    state = %{creator_id: creator_id, creators: %{}}
    state = update_creators(state, creator_id, machine_id())

    Phoenix.PubSub.subscribe(Chat.PubSub, @topic)
    Process.send_after(self(), :discover_creators, 100)

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:discover_creators, state) do
    schedule_discovery()
    broadcast_topic(:discover_request, state)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:discover_request, _node_pid, creator_id, machine_id}, state) do
    state = update_creators(state, creator_id, machine_id)
    broadcast_topic(:discover_reply, state)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:discover_reply, _node_pid, creator_id, machine_id}, state) do
    state = update_creators(state, creator_id, machine_id)
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  defp schedule_discovery() do
    Process.send_after(self(), :discover_creators, :timer.seconds(10))
  end

  defp broadcast_topic(topic, state) do
    Phoenix.PubSub.broadcast_from(
      Chat.PubSub,
      self(),
      @topic,
      {topic, self(), state.creator_id, machine_id()}
    )
  end

  defp update_creators(state, creator_id, machine_id) do
    creators = Map.put(state.creators, creator_id, machine_id)
    %{state | creators: creators}
  end

  defp machine_id(), do: Application.get_env(:chat, :fly_machine_id)
end
