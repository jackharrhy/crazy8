defmodule Crazy8Web.PlayerLive do
  require IEx

  use Crazy8Web, :live_component

  require Logger

  alias Crazy8.GameServer

  def render(assigns) do
    ~H"""
    <div>
      <.svelte
        name="Player"
        socket={@socket}
        props={%{game: @game, player: @player, myself: @myself.cid}}
      />
    </div>
    """
  end

  def handle_event("start-game", _, socket) do
    %{player: player, game: game} = socket.assigns

    case GameServer.start_game(game.code, player.id) do
      {:ok, game} ->
        {:noreply, assign(socket, game: game)}

      {:error, reason} ->
        {:noreply, put_temporary_flash(socket, :error, "#{reason}")}
    end
  end

  def handle_event("play-card", %{"cardIndex" => card_index}, socket)
      when is_integer(card_index) do
    %{player: player, game: game} = socket.assigns

    case GameServer.play_card(game.code, player.id, card_index) do
      {:ok, game} ->
        {:noreply, assign(socket, game: game)}

      {:error, reason} ->
        {:noreply, put_temporary_flash(socket, :error, "#{reason}")}
    end
  end

  def handle_event("draw-card", _, socket) do
    %{player: player, game: game} = socket.assigns

    case GameServer.draw_card(game.code, player.id) do
      {:ok, game} ->
        {:noreply, assign(socket, game: game)}

      {:error, reason} ->
        {:noreply, put_temporary_flash(socket, :error, "#{reason}")}
    end
  end

  defp put_temporary_flash(socket, level, message) do
    :timer.send_after(:timer.seconds(3), {:clear_flash, level})

    put_flash(socket, level, message)
  end
end
