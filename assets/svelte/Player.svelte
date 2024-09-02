<script>
  import { Toaster } from "$lib/components/ui/sonner";
  import { toast } from "svelte-sonner";

  export let player;
  export let game;

  export let live;
  export let myself;

  $: isPlayerHost = game.host === player.id;
  $: isPlayerTurn = game.turn === player.id;

  const suits = ["hearts", "diamonds", "clubs", "spades"];

  if (live) {
    live.handleEvent("flash", (event) => {
      toast[event.level](event.message, {
        duration: 5000,
      });
    });
  }

  function startGame() {
    live.pushEventTo(myself, "start-game", {});
  }

  function playCard(index) {
    live.pushEventTo(myself, "play-card", { cardIndex: index });
  }

  function drawCard() {
    live.pushEventTo(myself, "draw-card", {});
  }

  function pickNextSuit(suit) {
    live.pushEventTo(myself, "pick-next-suit", { suit: suit });
  }
</script>

<Toaster />

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

  {#if game.state === "playing" && game.turn_state === "play_or_draw_card" && isPlayerTurn}
    <button
      on:click={drawCard}
      class="bg-green-500 hover:bg-green-600 text-white font-bold py-2 px-4 rounded ml-4"
    >
      Draw Card
    </button>
  {/if}

  {#if game.turn_state === "pick_next_suit" && isPlayerTurn}
    <div class="flex flex-wrap justify-center items-center gap-4">
      {#each suits as suit}
        <button
          on:click={() => pickNextSuit(suit)}
          class="bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded mb-4"
        >
          {suit}
        </button>
      {/each}
    </div>
  {/if}
</div>
