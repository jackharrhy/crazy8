<script lang="ts">
  import { Button } from "$lib/components/ui/button";
  import { Input } from "$lib/components/ui/input";

  export let name = "";
  export let code = "";
</script>

<header class="flex justify-center text-2xl py-4">crazy8</header>

<div class="flex items-center flex-col gap-6 w-64 mx-auto">
  <form
    phx-change="update"
    phx-submit="join-game"
    class="flex flex-col gap-2 w-full"
  >
    <Input
      name="code"
      placeholder="game code"
      type="text"
      bind:value={code}
      phx-debounce="500"
    />
    <Input
      name="name"
      placeholder="your username"
      type="text"
      bind:value={name}
      phx-debounce="500"
    />
    <Button variant="outline" type="submit">join game</Button>
  </form>

  <div class="flex items-center w-full my-4">
    <div class="flex-grow border-t border-gray-300"></div>
    <span class="px-4 py-2 text-gray-500 text-sm uppercase">or</span>
    <div class="flex-grow border-t border-gray-300"></div>
  </div>

  <form phx-submit="create-game" class="flex flex-col gap-2 w-full">
    <Button variant="outline" type="submit">create game</Button>
    <p class="text-sm text-gray-500">
      do this on a screen all players can see, like the person in discord screen
      sharing, or a television
    </p>
  </form>

  <div class="flex items-center w-full my-4">
    <div class="flex-grow border-t border-gray-300"></div>
    <span class="px-4 py-2 text-gray-500 text-sm uppercase">or</span>
    <div class="flex-grow border-t border-gray-300"></div>
  </div>

  <form phx-submit="create-single-pane-game" class="flex flex-col gap-2 w-full">
    <Button variant="outline" type="submit">create single pane game</Button>
    <p class="text-sm text-gray-500">
      do this if you want to the entire play on a single screen, mostly built
      for testing purposes
    </p>
  </form>
</div>
