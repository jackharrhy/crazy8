defmodule Crazy8Web.LobbyLive do
  use Crazy8Web, :live_view

  alias Crazy8.GameServer

  def render(assigns) do
    ~H"""
    <.svelte name="Lobby" socket={@socket} props={%{name: @name, code: @code}} />
    """
  end

  def generate_code() do
    ?a..?z |> Enum.take_random(4) |> List.to_string() |> String.upcase()
  end

  def handle_event("create-game", _fields, socket) do
    code = generate_code()
    {:noreply, push_navigate(socket, to: ~p"/game/#{code}?name=#{socket.assigns.name}")}
  end

  def handle_event("update", fields, socket) do
    %{"code" => code} = fields
    {:noreply, assign(socket, code: code)}
  end

  def handle_event("join-game", fields, socket) do
    %{"code" => code, "name" => name} = fields

    if GameServer.game_exists?(code) do
      {:noreply, push_navigate(socket, to: ~p"/game/#{code}?join&name=#{name}")}
    else
      {:noreply, assign(socket, error: "#{code}: game not found")}
    end
  end

  def mount(_params, %{"session_id" => _session_id}, socket) do
    {:ok,
     assign(socket,
       code: "",
       name: "jack",
       error: nil,
       dev: Application.fetch_env!(:crazy8, :dev)
     )}
  end

  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: "/setup?return_to=/")}
  end
end
