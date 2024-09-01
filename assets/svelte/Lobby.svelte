<script lang="ts">
  import { Button } from "$lib/components/ui/button";
  import { Input } from "$lib/components/ui/input";

  export let name = "jack";
  export let code = "";
</script>

<header class="flex justify-center text-2xl py-4">crazy8</header>

<div class="flex items-center flex-col gap-6 w-64 mx-auto">
  <form
    data-phx-change="update"
    data-phx-submit="join-game"
    class="flex flex-col gap-2 w-full"
  >
    <Input
      name="code"
      placeholder="game code"
      type="text"
      bind:value={code}
      data-phx-debounce="500"
    />
    <Input
      name="name"
      placeholder="your username"
      type="text"
      bind:value={name}
      data-phx-debounce="500"
    />
    <Button variant="outline" type="submit">join game</Button>
  </form>

  <div class="flex items-center w-full my-4">
    <div class="flex-grow border-t border-gray-300"></div>
    <span class="px-4 py-2 text-gray-500 text-sm uppercase">or</span>
    <div class="flex-grow border-t border-gray-300"></div>
  </div>

  <form data-phx-submit="create-game" class="flex flex-col gap-2 w-full">
    <Button variant="outline" type="submit">create game</Button>
  </form>
</div>
