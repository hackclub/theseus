import { defineConfig } from 'vite'
import ViteRails from 'vite-plugin-rails'

export default defineConfig({
  plugins: [
    ViteRails(),
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
    include: ['d3', 'datamaps']
  }
})
