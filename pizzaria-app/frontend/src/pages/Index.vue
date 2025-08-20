<template>
  <q-page class="flex flex-center column">
    <div class="text-center q-pa-md">
      <h1 class="text-h3 text-primary q-mb-md">Bem-vindo à Pizzaria App</h1>
      <p class="text-h6 q-mb-xl">As melhores pizzas da cidade!</p>
      
      <q-img
        src="https://images.unsplash.com/photo-1513104890138-7c749659a591?ixlib=rb-1.2.1&auto=format&fit=crop&w=1050&q=80"
        style="height: 300px; max-width: 500px"
        class="rounded-borders q-mb-lg"
      />
      
      <div class="q-mt-lg">
        <q-btn
          color="primary"
          label="Ver Cardápio"
          icon="restaurant_menu"
          size="lg"
          to="/cardapio"
          class="q-mr-md"
        />
        <q-btn
          color="secondary"
          label="Fazer Pedido"
          icon="shopping_cart"
          size="lg"
          to="/pedido"
        />
      </div>
    </div>
    
    <div class="q-pa-md full-width">
      <h2 class="text-h4 text-center q-mb-md">Nossas Especialidades</h2>
      <div class="row q-col-gutter-md justify-center">
        <div v-for="pizza in destaques" :key="pizza.id" class="col-xs-12 col-sm-6 col-md-4">
          <q-card class="my-card">
            <q-card-section>
              <div class="text-h6">{{ pizza.nome }}</div>
              <div class="text-subtitle2">{{ pizza.ingredientes }}</div>
            </q-card-section>

            <q-card-section class="q-pt-none">
              <div class="text-h5 text-primary">R$ {{ pizza.preco.toFixed(2) }}</div>
            </q-card-section>

            <q-card-actions align="right">
              <q-btn flat color="primary" label="Adicionar ao Pedido" @click="adicionarAoCarrinho(pizza)" />
            </q-card-actions>
          </q-card>
        </div>
      </div>
    </div>
  </q-page>
</template>

<script>
import { defineComponent, computed, onMounted } from 'vue'
import { useStore } from 'vuex'
import { useQuasar } from 'quasar'

export default defineComponent({
  name: 'PageIndex',
  
  setup() {
    const store = useStore()
    const $q = useQuasar()
    
    onMounted(() => {
      store.dispatch('carregarPizzas')
    })
    
    const destaques = computed(() => {
      return store.state.pizzas.slice(0, 3)
    })
    
    const adicionarAoCarrinho = (pizza) => {
      store.commit('adicionarAoCarrinho', {
        pizza_id: pizza.id,
        quantidade: 1
      })
      
      $q.notify({
        color: 'positive',
        textColor: 'white',
        icon: 'shopping_cart',
        message: `${pizza.nome} adicionada ao carrinho!`
      })
    }
    
    return {
      destaques,
      adicionarAoCarrinho
    }
  }
})
</script>
