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
          art: String.t()
        }
  defstruct [:suit, :value, :type, :art]

  @spec new(atom(), integer(), atom()) :: t()
  def new(suit, value, type) do
    struct!(__MODULE__, %{
      suit: suit,
      value: value,
      type: type,
      art: generate_art(suit, value)
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

  @spec art_url(t()) :: String.t()
  def art_url(card) do
    suit = String.capitalize(Atom.to_string(card.suit))
    value = value_to_art(card.value)
    "/images/Cards/card#{suit}#{value}.png"
  end

  @spec can_play(t(), t()) :: :ok | {:error, atom()}
  def can_play(card, top_card) do
    if can_play?(card, top_card) do
      :ok
    else
      {:error, :invalid_play}
    end
  end

  @spec can_play?(t(), t()) :: boolean()
  def can_play?(card, top_card) do
    card.suit == top_card.suit or
      card.value == top_card.value or
      card.value == 8
  end
end

defimpl String.Chars, for: Crazy8.Card do
  def to_string(card) do
    "#{card.art}"
  end
end
