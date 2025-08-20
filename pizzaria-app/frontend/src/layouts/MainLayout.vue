<template>
  <q-layout view="lHh Lpr lFf">
    <q-header elevated class="bg-primary text-white">
      <q-toolbar>
        <q-btn
          flat
          dense
          round
          icon="menu"
          aria-label="Menu"
          @click="toggleLeftDrawer"
        />

        <q-toolbar-title>
          Pizzaria App
        </q-toolbar-title>

        <q-btn flat round dense icon="shopping_cart" to="/pedido">
          <q-badge color="red" floating v-if="carrinhoCount > 0">{{ carrinhoCount }}</q-badge>
        </q-btn>
      </q-toolbar>
    </q-header>

    <q-drawer
      v-model="leftDrawerOpen"
      show-if-above
      bordered
      class="bg-grey-1"
    >
      <q-list>
        <q-item-label header class="text-grey-8">Menu</q-item-label>

        <EssentialLink
          v-for="link in essentialLinks"
          :key="link.title"
          v-bind="link"
        />
      </q-list>
    </q-drawer>

    <q-page-container>
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<script>
import { defineComponent, ref, computed } from 'vue'
import { useStore } from 'vuex'

const linksList = [
  {
    title: 'Início',
    caption: 'Página inicial',
    icon: 'home',
    link: '/'
  },
  {
    title: 'Cardápio',
    caption: 'Nossas pizzas',
    icon: 'restaurant_menu',
    link: '/cardapio'
  },
  {
    title: 'Meu Pedido',
    caption: 'Faça seu pedido',
    icon: 'shopping_cart',
    link: '/pedido'
  },
  {
    title: 'Meus Pedidos',
    caption: 'Histórico de pedidos',
    icon: 'receipt',
    link: '/pedidos'
  },
  {
    title: 'Administração',
    caption: 'Gerenciar pedidos',
    icon: 'admin_panel_settings',
    link: '/admin'
  }
]

export default defineComponent({
  name: 'MainLayout',

  components: {
    EssentialLink: defineComponent({
      name: 'EssentialLink',
      props: {
        title: {
          type: String,
          required: true
        },

        caption: {
          type: String,
          default: ''
        },

        link: {
          type: String,
          default: '#'
        },

        icon: {
          type: String,
          default: ''
        }
      },
      setup(props) {
        return () => (
          <q-item clickable tag="a" to={props.link}>
            <q-item-section avatar>
              <q-icon name={props.icon} />
            </q-item-section>
            <q-item-section>
              <q-item-label>{props.title}</q-item-label>
              <q-item-label caption>{props.caption}</q-item-label>
            </q-item-section>
          </q-item>
        )
      }
    })
  },

  setup () {
    const leftDrawerOpen = ref(false)
    const store = useStore()

    const carrinhoCount = computed(() => {
      return store.state.carrinho.reduce((total, item) => total + item.quantidade, 0)
    })

    return {
      essentialLinks: linksList,
      leftDrawerOpen,
      carrinhoCount,
      toggleLeftDrawer () {
        leftDrawerOpen.value = !leftDrawerOpen.value
      }
    }
  }
})
</script>
