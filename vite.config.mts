import { defineConfig } from 'vite'
import ViteRails from 'vite-plugin-rails'
import { svelte } from '@sveltejs/vite-plugin-svelte'

export default defineConfig({
  plugins: [
    ViteRails(),
    svelte(),
  ],
  define: {
    'this': 'globalThis',
    'global': 'globalThis',
  },
  css: {
    preprocessorOptions: {
      scss: {
        api: 'modern-compiler'
      }
    },
    lightningcss: {
      errorRecovery: true,
    },
  },
  resolve: {
    alias: {
      '@': './app/frontend'
    },
    conditions: ['browser', 'import', 'module', 'default'],
  },
  build: {
    target: 'esnext' //browsers can handle the latest ES features
  },
  optimizeDeps: {
    include: ['d3', 'datamaps', '@primer/view-components'],
  }
})
