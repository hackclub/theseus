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
    // postcss: './postcss.config.js',
    preprocessorOptions: {
      scss: {
        api: 'modern-compiler' // or "modern"
      }
    }
  },
  resolve: {
    alias: {
      '@': './app/frontend'
    }
  },
  build: {
    target: 'esnext' //browsers can handle the latest ES features
  },
  optimizeDeps: {
    include: ['d3', 'datamaps', '@primer/view-components'],
    esbuildOptions: {
      keepNames: true
    }
  }
})
