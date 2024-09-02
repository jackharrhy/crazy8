defmodule Crazy8.Game do
  alias Crazy8.Player
  alias Crazy8.Deck
  alias Crazy8.Card
  require Logger

  @derive Jason.Encoder
  defstruct messages: [],
            code: nil,
            state: :setup,
            turn_state: :play_or_draw_card,
            next_suit: nil,
            players: [],
            deck: nil,
            host: nil,
            turn: nil,
            pile: [],
            discard: []

  @max_players 4

  @type game_state :: :setup | :playing | :game_over
  @type turn_state :: :play_or_draw_card | :pick_next_suit

  @type t :: %__MODULE__{
          messages: [String.t()],
          code: String.t() | nil,
          state: game_state,
          turn_state: turn_state,
          next_suit: atom() | nil,
          players: [Player.t()],
          deck: Deck.cards() | nil,
          host: String.t() | nil,
          turn: String.t() | nil,
          pile: [Deck.cards()],
          discard: [Deck.cards()]
        }

  @spec new(String.t()) :: t()
  def new(code) do
    struct!(
      __MODULE__,
      messages: [
        "game #{code} created"
      ],
      code: code
    )
  end

  @spec put_game_into_state(t(), game_state) :: t()
  def put_game_into_state(game, state) do
    Map.put(game, :state, state)
  end

  @spec new_message(t(), String.t()) :: t()
  def new_message(game, message) do
    game |> Map.put(:messages, [message | game.messages])
  end

  @spec hand_size(t()) :: non_neg_integer()
  def hand_size(game) do
    if length(game.players) == 2 do
      7
    else
      5
    end
  end

  @spec deal_hand(t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def deal_hand(game, player_id) do
    with {:ok, player} <- get_player_by_id(game, player_id),
         {:ok, {deck, hand}} <- Deck.deal_hand(game.deck, hand_size(game)) do
      player = %{player | hand: hand}
      player_index = get_player_index(game, player_id)

      Logger.debug("#{game.code}: Dealt #{length(hand)} cards to #{player}")

      game =
        game
        |> Map.put(:deck, deck)
        |> Map.put(:players, List.replace_at(game.players, player_index, player))
        |> new_message("player #{player} dealt hand")

      {:ok, game}
    end
  end

  @spec deal_hands(t()) :: t()
  def deal_hands(game) do
    Enum.reduce(game.players, game, fn player, game ->
      {:ok, {hand, deck}} = Deck.deal_hand(game.deck, hand_size(game))
      player = %{player | hand: hand}
      player_index = get_player_index(game, player.id)

      Logger.debug("#{game.code}: Dealt #{length(hand)} cards to #{player}")

      game
      |> Map.put(:deck, deck)
      |> Map.put(:players, List.replace_at(game.players, player_index, player))
      |> new_message("dealt hand to #{player}")
    end)
  end

  @spec add_player(t(), String.t(), String.t()) ::
          {:ok, t(), Player.t()} | {:error, atom()}
  def add_player(game, player_id, player_name) do
    if game.state == :setup do
      if length(game.players) >= @max_players do
        {:error, :game_full}
      else
        player = Player.new(player_id, player_name, [])

        game =
          if is_nil(game.host) do
            Map.put(game, :host, player_id)
          else
            game
          end

        Logger.debug("#{game.code}: Player #{player} joined")

        game =
          game
          |> Map.put(:players, game.players ++ [player])
          |> new_message("player #{player} joined")

        {:ok, game, player}
      end
    else
      {:error, :game_not_in_setup}
    end
  end

  @spec start_game(t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def start_game(game, player_id) do
    with :ok <- is_player_host(game, player_id),
         :ok <- is_game_in_state(game, :setup),
         :ok <- more_than_one_player(game),
         game <- put_game_into_state(game, :playing) do
      random_player_id = Enum.random(game.players) |> Map.get(:id)
      {:ok, player} = get_player_by_id(game, random_player_id)

      game =
        game
        |> Map.put(:deck, Deck.fresh_deck(length(game.players)) |> Deck.shuffle())
        |> deal_hands()
        |> Map.put(:turn, random_player_id)
        |> Map.put(:turn_state, :play_or_draw_card)

      {top_card, deck} = List.pop_at(game.deck, 0)

      Logger.debug(
        "#{game.code}: Starting game with #{player} going first, top card is #{top_card}"
      )

      game =
        game
        |> Map.put(:deck, deck)
        |> Map.put(:pile, [top_card])
        |> new_message("game started, #{player} goes first, top card is #{top_card}")

      {:ok, game}
    end
  end

  @spec play_card(t(), String.t(), non_neg_integer()) :: {:ok, t()} | {:error, atom()}
  def play_card(game, player_id, card_index) do
    with :ok <- is_game_in_state(game, :playing),
         {:ok, player} <- get_player_by_id(game, player_id),
         :ok <- is_player_turn(game, player_id),
         {:ok, card} <- get_card_by_index(player, card_index),
         :ok <- Card.can_play(card, hd(game.pile), game.next_suit) do
      game = game |> new_message("player #{player} played card #{card}")

      player = %{player | hand: List.delete_at(player.hand, card_index)}

      players =
        Enum.map(game.players, fn p ->
          if p.id == player_id, do: player, else: p
        end)

      pile = [card | game.pile]

      game =
        game
        |> Map.put(:pile, pile)
        |> Map.put(:players, players)
        |> Map.put(:next_suit, nil)

      game =
        if Enum.empty?(player.hand) do
          Logger.debug("#{game.code}: Player #{player} has won the game!")

          game
          |> put_game_into_state(:win)
          |> Map.put(:winner, player_id)
          |> new_message("#{player} has won the game!")
        else
          if card.value == 8 do
            Logger.debug(
              "#{game.code}: Player #{player} played an 8 and can now choose the next suit"
            )

            game
            |> Map.put(:turn_state, :pick_next_suit)
            |> new_message("#{player} played an 8 and can now choose the next suit")
          else
            Logger.debug("#{game.code}: Player #{player} played card #{card}")

            game |> next_player()
          end
        end

      {:ok, game}
    end
  end

  @spec draw_card(t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def draw_card(game, player_id) do
    with :ok <- is_game_in_state(game, :playing),
         {:ok, player} <- get_player_by_id(game, player_id),
         :ok <- is_player_turn(game, player_id),
         {:ok, {card, deck}} <- Deck.draw_card(game.deck) do
      player = %{player | hand: player.hand ++ [card]}

      Logger.debug("#{game.code}: Player #{player} drew card #{card}")

      game =
        game
        |> Map.put(:deck, deck)
        |> Map.put(
          :players,
          List.replace_at(game.players, get_player_index(game, player_id), player)
        )
        |> new_message("player #{player} drew card")

      {:ok, game}
    end
  end

  @spec pick_next_suit(t(), String.t(), atom()) :: {:ok, t()} | {:error, atom()}
  def pick_next_suit(game, player_id, suit) do
    with :ok <- is_game_in_state(game, :playing),
         {:ok, player} <- get_player_by_id(game, player_id),
         :ok <- is_player_turn(game, player_id),
         :ok <- is_turn_state(game, :pick_next_suit) do
      Logger.debug("#{game.code}: Player #{player} picked next suit #{suit}")

      game =
        game
        |> Map.put(:next_suit, suit)
        |> new_message("player #{player} picked next suit #{suit}")
        |> next_player()

      {:ok, game}
    end
  end

  @spec get_player_by_id(t(), String.t()) :: {:ok, Player.t()} | {:error, atom()}
  def get_player_by_id(game, player_id) do
    player = Enum.find(game.players, fn player -> player.id == player_id end)

    if player do
      {:ok, player}
    else
      {:error, :player_not_found}
    end
  end

  @spec next_player(t()) :: t()
  def next_player(game) do
    next_player_index = rem(get_player_index(game, game.turn) + 1, length(game.players))
    next_player = Enum.at(game.players, next_player_index)

    game
    |> Map.put(:turn, next_player.id)
    |> Map.put(:turn_state, :play_or_draw_card)
    |> new_message("it's now #{next_player}'s turn")
  end

  @spec is_game_in_state(t(), game_state) :: :ok | {:error, atom()}
  def is_game_in_state(game, state) do
    if game.state == state do
      :ok
    else
      {:error, :game_not_in_state}
    end
  end

  @spec is_turn_state(t(), turn_state) :: :ok | {:error, atom()}
  def is_turn_state(game, state) do
    if game.turn_state == state do
      :ok
    else
      {:error, :turn_not_in_state}
    end
  end

  @spec get_player_index(t(), String.t()) :: non_neg_integer() | nil
  def get_player_index(game, player_id) do
    Enum.find_index(game.players, fn player -> player.id == player_id end)
  end

  @spec get_card_by_index(Player.t(), non_neg_integer()) ::
          {:ok, Deck.cards()} | {:error, atom()}
  def get_card_by_index(player, card_index) do
    card = Enum.at(player.hand, card_index)

    if card do
      {:ok, card}
    else
      {:error, :card_not_found}
    end
  end

  @spec more_than_one_player(t()) :: :ok | {:error, atom()}
  def more_than_one_player(game) do
    if more_than_one_player?(game) do
      :ok
    else
      {:error, :not_enough_players}
    end
  end

  @spec more_than_one_player?(t()) :: boolean()
  def more_than_one_player?(game) do
    length(game.players) > 1
  end

  @spec is_player_host(t(), String.t()) :: :ok | {:error, atom()}
  def is_player_host(game, player_id) do
    if is_player_host?(game, player_id) do
      :ok
    else
      {:error, :not_host}
    end
  end

  @spec is_player_host?(t(), String.t()) :: boolean()
  def is_player_host?(game, player_id) do
    player_id == game.host
  end

  @spec is_player_turn(t(), String.t()) :: :ok | {:error, atom()}
  def is_player_turn(game, player_id) do
    if is_players_turn?(game, player_id) do
      :ok
    else
      {:error, :not_players_turn}
    end
  end

  @spec is_players_turn?(t(), String.t()) :: boolean()
  def is_players_turn?(game, player_id) do
    player_id == game.turn
  end
end
