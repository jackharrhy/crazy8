defmodule Crazy8Web.MainComponent do
  use Crazy8Web, :live_component

  def render(assigns) do
    ~H"""
    <div class="h-full">
      <.svelte name="Main" socket={@socket} props={%{game: @game}} class="h-full" />
    </div>
    """
  end
end
