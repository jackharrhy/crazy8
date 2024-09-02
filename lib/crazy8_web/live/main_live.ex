defmodule Crazy8Web.MainLive do
  use Crazy8Web, :live_view

  alias Crazy8.GameServer
  alias Crazy8.GameSupervisor

  require Logger

  def mount(%{"code" => code} = params, _session, socket) do
    debug = Map.has_key?(params, "debug")

    socket = assign(socket, debug: debug)

    unless GameServer.game_exists?(code) do
      Logger.debug("Starting game #{code}")
      GameSupervisor.start_game(code)
    else
      Logger.debug("Game already exists #{code}")
    end

    if connected?(socket) do
      :ok = Phoenix.PubSub.subscribe(Crazy8.PubSub, code)
    end

    {:ok, game} = GameServer.get_game(code)
    socket = assign(socket, game: game)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.live_component module={Crazy8Web.MainComponent} id="main" game={@game} />
    """
  end

  def handle_info(%{event: :game_updated, payload: %{game: game}}, socket) do
    socket = assign(socket, game: game)
    {:noreply, socket}
  end
end
