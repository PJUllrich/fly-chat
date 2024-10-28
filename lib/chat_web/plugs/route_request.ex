defmodule ChatWeb.Plugs.RouteRequest do
  use Plug.Builder, init_mode: :runtime

  import Plug.Conn

  require Logger

  @machine_id_key "fly-machine-id"

  def call(conn, opts) do
    conn
    |> fetch_query_params()
    |> fetch_cookies()
    |> handle_conn(opts)
  end

  def handle_conn(%Plug.Conn{params: %{"region" => region} = params} = conn, _opts) do
    machine_region = Application.get_env(:chat, :fly_region)
    machine_id = Application.get_env(:chat, :fly_machine_id)
    region_redirect = Map.get(params, "state") == "region-redirect"

    cookie_machine_id = Map.get(conn.req_cookies, @machine_id_key, machine_id)

    cond do
      region != machine_region ->
        redirect_to_region(conn, region, machine_region)

      !region_redirect && cookie_machine_id != machine_id ->
        redirect_to_machine(conn, cookie_machine_id, machine_id)

      true ->
        six_days = 6 * 24 * 60 * 60 * 1000
        put_resp_cookie(conn, @machine_id_key, machine_id, max_age: six_days)
    end
  end

  def handle_conn(conn, _opts), do: IO.inspect(conn)

  defp redirect_to_region(conn, region, machine_region) do
    Logger.info("Replaying request from region #{machine_region} to #{region}")

    conn
    |> put_resp_header("fly-replay", "region=#{region};state=region-redirect")
    |> Phoenix.Controller.text("redirecting...")
    |> halt()
  end

  defp redirect_to_machine(conn, cookie_machine_id, machine_id) do
    Logger.info("Replaying request from machine #{machine_id} to #{cookie_machine_id}")

    conn
    |> put_resp_header("fly-replay", "instance=#{cookie_machine_id}")
    |> Phoenix.Controller.text("redirecting...")
    |> halt()
  end
end
