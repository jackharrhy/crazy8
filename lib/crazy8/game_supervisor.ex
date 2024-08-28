defmodule Crazy8.GameSupervisor do
  use DynamicSupervisor

  alias Crazy8.GameServer

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(nil) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_game(code) do
    child_spec = %{
      id: GameServer,
      start: {GameServer, :start_link, [code]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def stop_game(code) do
    case GameServer.game_pid(code) do
      pid when is_pid(pid) ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)

      nil ->
        :ok
    end
  end
end
