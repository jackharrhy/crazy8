defmodule Crazy8Web.GameLive do
  use Crazy8Web, :live_view

  alias Crazy8.Game
  alias Crazy8.GameServer
  alias Crazy8.GameSupervisor

  require Logger

  def mount(%{"code" => code} = params, %{"session_id" => session_id}, socket) do
    debug = Map.has_key?(params, "debug")

    name = Map.get(params, "name")

    socket =
      assign(socket,
        debug: debug,
        session_id: session_id,
        name: name
      )

    unless GameServer.game_exists?(code) do
      Logger.debug("Starting game #{code}")
      GameSupervisor.start_game(code)
    else
      Logger.debug("Game already exists #{code}")
    end

    {:ok, game} = GameServer.get_game(code)

    auto_join = Map.has_key?(params, "join") || length(game.players) == 0

    socket = assign(socket, game: game)

    socket =
      case GameServer.get_player_by_id(code, session_id) do
        {:ok, player} ->
          assign(socket, player: player)

        {:error, _reason} ->
          assign(socket, player: nil)
      end

    socket =
      if connected?(socket) do
        :ok = Phoenix.PubSub.subscribe(Crazy8.PubSub, code)

        can_join = is_nil(socket.assigns.player) && !is_nil(name)

        if can_join && auto_join do
          add_self_to_game(socket)
        else
          socket
        end
      else
        socket
      end

    {:ok, socket}
  end

  def mount(%{"code" => code}, _session, socket) do
    {:ok, redirect(socket, to: "/setup?return_to=/game/#{code}")}
  end

  def render(assigns) do
    ~H"""
    <div>
      <p>game</p>
    </div>

    <%= if @debug do %>
      <div class="bg-black text-white p-4 mb-2">
        <p>player</p>
         <code><pre><%= Jason.encode!(@player, pretty: true) %></pre></code>
        <p>game</p>
         <code><pre><%= Jason.encode!(@game, pretty: true) %></pre></code>
      </div>
    <% end %>
    """
  end

  def handle_info(%{event: :game_updated, payload: %{game: game}}, socket) do
    socket = assign(socket, game: game)

    session_id = socket.assigns.session_id

    socket =
      case Game.get_player_by_id(game, session_id) do
        {:ok, player} ->
          assign(socket, player: player)

        {:error, _reason} ->
          assign(socket, player: nil)
      end

    {:noreply, socket}
  end

  def add_self_to_game(socket) do
    %{
      game: game,
      session_id: session_id,
      name: name
    } = socket.assigns

    case GameServer.add_player(game.code, session_id, name) do
      {:ok, game, player} ->
        socket
        |> assign(game: game, player: player)

      {:error, reason} ->
        socket
        |> put_temporary_flash(:error, "#{reason}")
    end
  end

  defp put_temporary_flash(socket, level, message) do
    :timer.send_after(:timer.seconds(3), {:clear_flash, level})

    put_flash(socket, level, message)
  end
end
