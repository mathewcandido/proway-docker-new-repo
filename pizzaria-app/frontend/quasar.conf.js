const { configure } = require('quasar/wrappers');

module.exports = configure(function (ctx) {
  return {
    supportTS: false,
    boot: [
      'axios',
    ],
    css: [
      'app.scss'
    ],
    extras: [
      'roboto-font',
      'material-icons',
    ],
    build: {
      vueRouterMode: 'hash',
      chainWebpack (chain) {
        chain.plugin('eslint-webpack-plugin')
          .use(require('eslint-webpack-plugin'), [{
            extensions: [ 'js', 'vue' ]
          }])
      },
      // Add this to fix the Sass math issue
      sassLoaderOptions: {
        additionalData: '@use "sass:math";'
      }
    },
    devServer: {
      https: false,
      port: 8080,
      open: true
    },
    framework: {
      config: {},
      plugins: [
        'Notify',
        'Dialog'
      ]
    },
    animations: [],
    ssr: {
      pwa: false,
      prodPort: 3000,
      middlewares: [
        'render'
      ]
    },
    pwa: {
      workboxPluginMode: 'GenerateSW',
      workboxOptions: {},
      manifest: {
        name: `Pizzaria App`,
        short_name: `Pizzaria App`,
        description: `Frontend para sistema de pizzaria`,
        display: 'standalone',
        orientation: 'portrait',
        background_color: '#ffffff',
        theme_color: '#027be3',
        icons: [
          {
            src: 'icons/icon-128x128.png',
            sizes: '128x128',
            type: 'image/png'
          },
          {
            src: 'icons/icon-192x192.png',
            sizes: '192x192',
            type: 'image/png'
          },
          {
            src: 'icons/icon-256x256.png',
            sizes: '256x256',
            type: 'image/png'
          },
          {
            src: 'icons/icon-384x384.png',
            sizes: '384x384',
            type: 'image/png'
          },
          {
            src: 'icons/icon-512x512.png',
            sizes: '512x512',
            type: 'image/png'
          }
        ]
      }
    },
    cordova: {
    },
    capacitor: {
      hideSplashscreen: true
    },
    electron: {
      bundler: 'packager',
      packager: {
      },
      builder: {
        appId: 'pizzaria-app'
      }
    }
  }
});
