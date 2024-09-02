defmodule Crazy8.GameSupervisor do
  use DynamicSupervisor

  alias Crazy8.GameServer

  require Logger

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(nil) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_game(code) do
    true = GameServer.code_valid?(code)

    child_spec = %{
      id: GameServer,
      start: {GameServer, :start_link, [code]},
      restart: :transient
    }

    Logger.debug("Supervisor starting up game server: #{code}")

    {:ok, _} = DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def stop_game(code) do
    case GameServer.game_pid(code) do
      pid when is_pid(pid) ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)

      nil ->
        :ok
    end
  end

  def stop_all_games do
    Logger.info("Stopping all game servers")

    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.each(fn {_, pid, _, _} ->
      DynamicSupervisor.terminate_child(__MODULE__, pid)
    end)

    :ok
  end
end
