defmodule Crazy8.Deck do
  alias Crazy8.Card

  @type cards :: [Card.t()]

  @spec fresh_deck(non_neg_integer()) :: cards()
  def fresh_deck(num_players) do
    if num_players <= 4 do
      fresh_deck()
    else
      fresh_deck() ++ fresh_deck()
    end
  end

  @spec fresh_deck() :: cards()
  def fresh_deck() do
    for suit <- Card.suits(), value <- Card.values() do
      if value > 10 or value < 13 do
        Card.new(suit, value, :face)
      else
        Card.new(suit, value, :number)
      end
    end
  end

  @spec shuffle(cards()) :: cards()
  def shuffle(deck) do
    Enum.shuffle(deck)
  end

  @spec deal_hand(cards(), non_neg_integer()) ::
          {:ok, {cards(), cards()}} | {:error, atom()}
  def deal_hand(deck, hand_size) do
    if hand_size > length(deck) do
      {:error, :not_enough_cards}
    else
      {hand, remaining_deck} = Enum.split(deck, hand_size)
      {:ok, {hand, remaining_deck}}
    end
  end

  @spec draw_card(cards()) :: {:ok, {Card.t(), cards()}} | {:error, atom()}
  def draw_card(deck) do
    case deck do
      [] -> {:error, :not_enough_cards}
      [card | rest] -> {:ok, {card, rest}}
    end
  end
end
