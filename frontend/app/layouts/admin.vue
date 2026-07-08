<script setup lang="ts">
// Layout da área administrativa: tema dark e SEM área de anúncios (ver 003/004).
useHead({ htmlAttrs: { 'data-theme': 'dark' } })
</script>

<template>
  <div class="min-h-screen bg-bg text-content">
    <slot />
  </div>
</template>
