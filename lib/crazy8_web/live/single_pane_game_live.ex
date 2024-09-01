defmodule Crazy8Web.SinglePaneGameLive do
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

    {:ok, game} = GameServer.get_game(code)

    if length(game.players) == 0 do
      player_names = ["jack", "marty", "natalie", "ethan"]

      for name <- player_names do
        GameServer.add_player(code, name, name)
      end
    end

    socket = assign(socket, game: game)

    if connected?(socket) do
      :ok = Phoenix.PubSub.subscribe(Crazy8.PubSub, code)
    end

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-2 grid-rows-[1.5fr_1fr_1fr] gap-0 h-full">
      <div class="col-span-2 border border-stone-300">
        <.live_component module={Crazy8Web.MainComponent} id="main" game={@game} />
      </div>
      <%= for {player, index} <- Enum.with_index(@game.players) do %>
        <div class={"#{player_area_class(index)} border border-stone-300"}>
          <div class="border-b border-stone-300 py-.5 px-1 text-xs">
            <p>
              <%= player.name %>
            </p>
          </div>
          <.live_component
            module={Crazy8Web.PlayerComponent}
            id={"player-#{player.id}"}
            game={@game}
            player={player}
          />
        </div>
      <% end %>
    </div>
    """
  end

  defp player_area_class(index) do
    case index do
      0 -> "col-start-1 row-start-2"
      1 -> "col-start-2 row-start-2"
      2 -> "col-start-1 row-start-3"
      3 -> "col-start-2 row-start-3"
      _ -> ""
    end
  end

  def handle_info(%{event: :game_updated, payload: %{game: game}}, socket) do
    Logger.debug("Game #{game.code} updated")
    socket = assign(socket, game: game)
    {:noreply, socket}
  end
end
