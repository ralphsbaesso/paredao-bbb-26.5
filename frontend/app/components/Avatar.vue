<script setup lang="ts">
/**
 * Avatar de participante (rosto estilo emoji) — SVG inline (ver 005-avatars.md).
 *
 * Recebe o NOME da variante (vocabulário estável compartilhado com o backend) e
 * renderiza o rosto correspondente diretamente como <svg> no DOM. Nome ausente
 * ou desconhecido cai no avatar de fallback, sem quebrar a renderização.
 *
 * Cor: a arte usa `currentColor`, então herda a cor do contexto (tokens `--bbb-*`)
 * e funciona nos temas light e dark. Ajuste com utilitários de cor (ex.:
 * `text-primary`) ou CSS no consumidor.
 *
 * Tamanho: controlável via prop `size` (número em px ou string CSS) e/ou CSS.
 *
 * Acessibilidade: informe `label` (ex.: o nome do participante) para expor o
 * avatar como imagem rotulada; sem `label` — ou com `decorative` — o SVG é
 * marcado como decorativo (`aria-hidden`), ideal quando o nome já aparece ao lado.
 */
import { computed } from 'vue'
import { avatarInnerSvg } from '~/utils/avatars'

const props = withDefaults(
  defineProps<{
    variant?: string | null
    label?: string
    size?: number | string
    decorative?: boolean
  }>(),
  {
    variant: null,
    label: undefined,
    size: '2.5rem',
    decorative: false,
  },
)

const inner = computed(() => avatarInnerSvg(props.variant))

const dimension = computed(() =>
  typeof props.size === 'number' ? `${props.size}px` : props.size,
)

const isDecorative = computed(() => props.decorative || !props.label)
</script>

<template>
  <svg
    class="avatar"
    viewBox="0 0 64 64"
    :width="dimension"
    :height="dimension"
    :role="isDecorative ? undefined : 'img'"
    :aria-hidden="isDecorative ? 'true' : undefined"
    :aria-label="isDecorative ? undefined : label"
    v-html="inner"
  />
</template>

<style scoped>
.avatar {
  display: inline-block;
  flex: none;
  vertical-align: middle;
}
</style>
