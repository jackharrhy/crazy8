<script>
  export let game;

  function isPlayerHost(player) {
    return game.host === player.id;
  }

  function isPlayersTurn(player) {
    return player.id === game.turn;
  }
</script>

<div class="flex h-full">
  <div class="flex-1 flex flex-col gap-8">
    <div class="border-b p-2">
      <div class="flex flex-wrap justify-center items-center gap-4">
        <p>State: {game.state}</p>

        <div class="flex flex-wrap justify-center items-center gap-2">
          {#each game.players as gamePlayer}
            <div
              class="bg-blue-100 text-blue-900 px-3 py-1 rounded-sm border border-blue-300"
            >
              {#if game.state === "setup" && isPlayerHost(gamePlayer)}
                👑
              {/if}

              {#if game.state === "playing" && isPlayersTurn(gamePlayer)}
                🡒
              {/if}
              {gamePlayer.name}
              {gamePlayer.art}
            </div>
          {/each}
        </div>
      </div>
    </div>

    {#if game.state === "playing"}
      <div class="flex flex-wrap justify-center items-center h-full">
        <div class="flex flex-col items-center">
          {#if game.next_suit}
            <p>Next suit: {game.next_suit}</p>
          {/if}
          <img src={game.pile[0].art_url} class="p-4" alt="Top card" />
        </div>
      </div>
    {/if}
  </div>

  <div class="flex flex-col border-x p-2 h-full overflow-y-auto">
    <ul class="list-none">
      {#each game.messages as message}
        <li>{message}</li>
      {/each}
    </ul>
  </div>
</div>
