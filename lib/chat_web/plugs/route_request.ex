defmodule ChatWeb.Plugs.RouteRequest do
  use Plug.Builder

  import Plug.Conn

  require Logger

  @machine_id_key "fly-machine-id"

  def call(conn, opts) do
    conn
    |> fetch_query_params()
    |> fetch_cookies()
    |> handle_conn(opts)
  end

  def handle_conn(%Plug.Conn{params: params} = conn, _opts) do
    IO.inspect(conn)
    machine_region = Application.get_env(:chat, :fly_region)
    machine_id = Application.get_env(:chat, :fly_machine_id)

    requested_region = Map.get(params, "region")
    # Ignore mismatching machine IDs if the region was changed because
    # we need to connect to a new machine from the new region instead.
    region_redirect =
      conn
      |> get_req_header("fly-replay-src")
      |> parse_header()
      |> case do
        %{"state" => "region-redirect"} -> true
        _ -> false
      end

    cookie_machine_id = Map.get(conn.req_cookies, @machine_id_key, machine_id)

    cond do
      requested_region && requested_region != machine_region ->
        redirect_to_region(conn, requested_region, machine_region)

      !region_redirect && cookie_machine_id != machine_id ->
        redirect_to_machine(conn, cookie_machine_id, machine_id)

      true ->
        Logger.info("Letting request pass through in #{machine_region} on #{machine_id}")
        six_days = 6 * 24 * 60 * 60 * 1000
        put_resp_cookie(conn, @machine_id_key, machine_id, max_age: six_days)
    end
  end

  defp parse_header([]), do: %{}

  defp parse_header([header]) do
    header
    |> String.split(";")
    |> Enum.map(fn element -> element |> String.split("=") |> List.to_tuple() end)
    |> Map.new()
  end

  defp redirect_to_region(conn, region, machine_region) do
    Logger.info("Replaying request from region #{machine_region} to #{region}")

    conn
    |> put_resp_header("fly-replay", "region=#{region};state=region-redirect")
    |> put_status(307)
    |> Phoenix.Controller.text("redirecting...")
    |> halt()
  end

  defp redirect_to_machine(conn, cookie_machine_id, machine_id) do
    Logger.info("Replaying request from machine #{machine_id} to #{cookie_machine_id}")

    conn
    |> put_resp_header("fly-replay", "instance=#{cookie_machine_id}")
    |> put_status(307)
    |> Phoenix.Controller.text("redirecting...")
    |> halt()
  end
end
