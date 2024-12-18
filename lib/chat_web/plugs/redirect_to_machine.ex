defmodule ChatWeb.Plugs.RedirectToMachine do
  use Plug.Builder

  import Plug.Conn

  require Logger

  @cookie_key "fly-machine-id"
  @cookie_ttl 6 * 24 * 60 * 60 * 1000

  def call(conn, opts) do
    conn
    |> fetch_query_params()
    |> fetch_cookies()
    |> handle_conn(opts)
  end

  def handle_conn(%Plug.Conn{params: params} = conn, _opts) do
    machine_id = Application.get_env(:chat, :fly_machine_id)
    param_id = Map.get(params, "instance")
    cookie_id = Map.get(conn.req_cookies, @cookie_key, machine_id)

    cond do
      param_id && param_id == machine_id ->
        Logger.info("Correct machine based on parameter #{param_id}. Set cookie and let pass.")
        put_resp_cookie(conn, @cookie_key, machine_id, max_age: @cookie_ttl)

      param_id && param_id != machine_id ->
        Logger.info("Incorrect machine #{machine_id} based on parameter #{param_id}. Redirect.")
        redirect_to_machine(conn, param_id)

      cookie_id && cookie_id == machine_id ->
        Logger.info("Correct machine based on cookie #{cookie_id}. Let pass.")
        conn

      cookie_id && cookie_id != machine_id ->
        Logger.info("Incorrect machine #{machine_id} based on cookie #{cookie_id}. Redirect.")
        redirect_to_machine(conn, cookie_id)

      true ->
        Logger.info("No parameter or cookie. Let pass.")
        conn
    end
  end

  defp redirect_to_machine(conn, requested_machine) do
    conn
    |> put_resp_header("fly-replay", "instance=#{requested_machine}")
    |> put_status(307)
    |> Phoenix.Controller.text("redirecting...")
    |> halt()
  end
end
