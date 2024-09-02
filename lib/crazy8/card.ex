defmodule Crazy8.Card do
  @suits [:hearts, :diamonds, :clubs, :spades]
  @values [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
  @types [:number, :face]

  @spec suits() :: [atom()]
  def suits do
    @suits
  end

  @spec values() :: [integer()]
  def values do
    @values
  end

  @spec types() :: [atom()]
  def types do
    @types
  end

  @derive Jason.Encoder
  @type t :: %__MODULE__{
          suit: atom(),
          value: integer(),
          type: :face | :number,
          art: String.t(),
          art_url: String.t()
        }
  defstruct [:suit, :value, :type, :art, :art_url]

  @spec new(atom(), integer(), atom()) :: t()
  def new(suit, value, type) do
    suit_formatted_for_url = String.capitalize(Atom.to_string(suit))
    value_formatted_for_url = value_to_art(value)
    art_url = "/images/Cards/card#{suit_formatted_for_url}#{value_formatted_for_url}.png"

    struct!(__MODULE__, %{
      suit: suit,
      value: value,
      type: type,
      art: generate_art(suit, value),
      art_url: art_url
    })
  end

  @spec value_to_art(integer()) :: String.t() | integer()
  defp value_to_art(value) do
    case value do
      1 -> "A"
      11 -> "J"
      12 -> "Q"
      13 -> "K"
      _ -> value
    end
  end

  @spec generate_art(atom(), integer()) :: String.t()
  defp generate_art(suit, value) do
    suit_art =
      case suit do
        :clubs -> "♣"
        :diamonds -> "♦"
        :hearts -> "♥"
        :spades -> "♠"
      end

    value_art = value_to_art(value)

    "#{suit_art} #{value_art}"
  end

  @spec can_play(t(), t(), atom() | nil) :: :ok | {:error, atom()}
  def can_play(card, top_card, next_suit) do
    if can_play?(card, top_card, next_suit) do
      :ok
    else
      {:error, :invalid_play}
    end
  end

  @spec can_play?(t(), t(), atom() | nil) :: boolean()
  def can_play?(card, top_card, next_suit) do
    if !is_nil(next_suit) do
      card.suit == next_suit or
        card.value == 8
    else
      card.suit == top_card.suit or
        card.value == top_card.value or
        card.value == 8
    end
  end
end

defimpl String.Chars, for: Crazy8.Card do
  def to_string(card) do
    "#{card.art}"
  end
end
