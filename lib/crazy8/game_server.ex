defmodule Crazy8.GameServer do
  use GenServer
  alias Crazy8.Game
  require Logger

  def generate_code() do
    ?a..?z |> Enum.take_random(4) |> List.to_string() |> String.upcase()
  end

  def code_valid?(code) do
    code |> String.match?(~r/^[A-Z]{4}$/)
  end

  def start_link(code) do
    Logger.info("Game server starting #{code}")
    GenServer.start(__MODULE__, code, name: via_tuple(code))
  end

  def game_pid(code) do
    code
    |> via_tuple()
    |> GenServer.whereis()
  end

  def game_exists?(code), do: game_pid(code) != nil

  def get_game(code), do: call_by_code(code, :get_game)
  def get_player_by_id(code, player_id), do: call_by_code(code, {:get_player_by_id, player_id})

  def add_player(code, player_id, player_name),
    do: call_by_code(code, {:add_player, player_id, player_name})

  def start_game(code, player_id), do: call_by_code(code, {:start_game, player_id})

  def play_card(code, player_id, card_index),
    do: call_by_code(code, {:play_card, player_id, card_index})

  def draw_card(code, player_id), do: call_by_code(code, {:draw_card, player_id})

  def pick_next_suit(code, player_id, suit),
    do: call_by_code(code, {:pick_next_suit, player_id, suit})

  def broadcast!(code, event, payload \\ %{}) do
    Phoenix.PubSub.broadcast!(Crazy8.PubSub, code, %{event: event, payload: payload})
  end

  @impl GenServer
  def init(code), do: {:ok, %{game: Game.new(code)}}

  @impl GenServer
  def handle_call(:get_game, _from, state), do: {:reply, {:ok, state.game}, state}

  @impl GenServer
  def handle_call({:add_player, player_id, player_name}, _from, state) do
    case Game.add_player(state.game, player_id, player_name) do
      {:ok, game, player} ->
        broadcast_game_updated!(game.code, game)
        {:reply, {:ok, game, player}, %{state | game: game}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:get_player_by_id, player_id}, _from, state) do
    {:reply, Game.get_player_by_id(state.game, player_id), state}
  end

  @impl GenServer
  def handle_call({:start_game, player_id}, _from, state) do
    case Game.start_game(state.game, player_id) do
      {:ok, game} ->
        broadcast_game_updated!(game.code, game)
        {:reply, {:ok, game}, %{state | game: game}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:play_card, player_id, card_index}, _from, state) do
    case Game.play_card(state.game, player_id, card_index) do
      {:ok, game} ->
        broadcast_game_updated!(game.code, game)
        {:reply, {:ok, game}, %{state | game: game}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:draw_card, player_id}, _from, state) do
    case Game.draw_card(state.game, player_id) do
      {:ok, game} ->
        broadcast_game_updated!(game.code, game)
        {:reply, {:ok, game}, %{state | game: game}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:pick_next_suit, player_id, suit}, _from, state) do
    case Game.pick_next_suit(state.game, player_id, suit) do
      {:ok, game} ->
        broadcast_game_updated!(game.code, game)
        {:reply, {:ok, game}, %{state | game: game}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_info({:put_game_into_state, game_state}, state) do
    game = Game.put_game_into_state(state.game, game_state)
    broadcast_game_updated!(game.code, game)
    {:noreply, %{state | game: game}}
  end

  defp via_tuple(code), do: {:via, Registry, {Crazy8.GameRegistry, code}}

  defp call_by_code(code, command) do
    case game_pid(code) do
      game_pid when is_pid(game_pid) -> GenServer.call(game_pid, command)
      nil -> {:error, :game_not_found}
    end
  end

  defp broadcast_game_updated!(code, game) do
    broadcast!(code, :game_updated, %{game: game})
  end
end
