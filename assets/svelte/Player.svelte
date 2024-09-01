<script>
  export let player;
  export let game;

  export let live;
  export let myself;

  let isPlayerHost = game.host === player.id;
  let isPlayerTurn = game.turn === player.id;

  function startGame() {
    live.pushEventTo(myself, "start-game", {});
  }

  function playCard(index) {
    live.pushEventTo(myself, "play-card", { cardIndex: index });
  }

  function drawCard() {
    live.pushEventTo(myself, "draw-card", {});
  }
</script>

<div class="flex flex-col flex-wrap justify-center items-center p-4">
  {#if game.state === "setup"}
    {#if isPlayerHost}
      {#if game.players.length > 1}
        <button
          on:click={() => startGame()}
          class="bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded mb-4"
        >
          start game
        </button>
      {:else}
        <p class="text-yellow-600 font-semibold mb-4">
          waiting for more players to join...
        </p>
      {/if}
    {:else}
      <p class="text-gray-600 italic mb-4">
        waiting for host to start the game...
      </p>
    {/if}
  {/if}

  <div class="flex flex-wrap justify-center items-center gap-4">
    {#each player.hand as card, index}
      <button
        on:click={() => playCard(index)}
        class="p-0 bg-transparent border-none"
      >
        <img
          src={card.art_url}
          alt="Card"
          class="p-4 hover:scale-105 transition-transform duration-150"
        />
      </button>
    {/each}
  </div>

  {#if game.state === "playing" && isPlayerTurn}
    <button
      on:click={drawCard}
      class="bg-green-500 hover:bg-green-600 text-white font-bold py-2 px-4 rounded ml-4"
    >
      Draw Card
    </button>
  {/if}
</div>
