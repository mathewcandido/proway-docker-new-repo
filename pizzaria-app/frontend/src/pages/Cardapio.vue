<template>
  <q-page padding>
    <h1 class="text-h4 text-center q-mb-lg">Nosso Cardápio</h1>
    
    <div class="row q-col-gutter-md">
      <div v-for="pizza in pizzas" :key="pizza.id" class="col-xs-12 col-sm-6 col-md-4">
        <q-card class="my-card">
          <q-card-section>
            <div class="text-h6">{{ pizza.nome }}</div>
            <div class="text-subtitle2">{{ pizza.ingredientes }}</div>
          </q-card-section>

          <q-card-section class="q-pt-none">
            <div class="text-h5 text-primary">R$ {{ pizza.preco.toFixed(2) }}</div>
          </q-card-section>

          <q-card-actions align="between">
            <q-btn-group spread>
              <q-btn color="negative" icon="remove" @click="diminuirQuantidade(pizza.id)" />
              <q-btn disable class="text-black">{{ getQuantidade(pizza.id) }}</q-btn>
              <q-btn color="positive" icon="add" @click="aumentarQuantidade(pizza.id)" />
            </q-btn-group>
            <q-btn 
              color="primary" 
              label="Adicionar" 
              :disable="getQuantidade(pizza.id) === 0"
              @click="adicionarAoCarrinho(pizza)"
            />
          </q-card-actions>
        </q-card>
      </div>
    </div>
    
    <div class="fixed-bottom-right q-ma-md" v-if="totalItens > 0">
      <q-btn
        round
        color="primary"
        icon="shopping_cart"
        size="lg"
        to="/pedido"
      >
        <q-badge color="red" floating>{{ totalItens }}</q-badge>
      </q-btn>
    </div>
  </q-page>
</template>

<script>
import { defineComponent, ref, computed, onMounted } from 'vue'
import { useStore } from 'vuex'
import { useQuasar } from 'quasar'

export default defineComponent({
  name: 'PageCardapio',
  
  setup() {
    const store = useStore()
    const $q = useQuasar()
    const quantidades = ref({})
    
    onMounted(() => {
      store.dispatch('carregarPizzas')
    })
    
    const pizzas = computed(() => store.state.pizzas)
    
    const totalItens = computed(() => {
      return Object.values(quantidades.value).reduce((total, quantidade) => total + quantidade, 0)
    })
    
    const getQuantidade = (pizzaId) => {
      return quantidades.value[pizzaId] || 0
    }
    
    const aªmentarQuantidade = (pizzaId) => {
      if (!quantidades.value[pizzaId]) {
        quantidades.value[pizzaId] = 0
      }
      quantidades.value[pizzaId]++
    }
    
    const diminuirQuantidade = (pizzaId) => {
      if (quantidades.value[pizzaId] && quantidades.value[pizzaId] > 0) {
        quantidades.value[pizzaId]--
      }
    }
    
    const adicionarAoCarrinho = (pizza) => {
      const quantidade = quantidades.value[pizza.id] || 0
      
      if (quantidade > 0) {
        store.commit('adicionarAoCarrinho', {
          pizza_id: pizza.id,
          quantidade: quantidade
        })
        
        quantidades.value[pizza.id] = 0
        
        $q.notify({
          color: 'positive',
          textColor: 'white',
          icon: 'shopping_cart',
          message: `${quantidade}x ${pizza.nome} adicionada ao carrinho!`
        })
      }
    }
    
    return {
      pizzas,
      quantidades,
      totalItens,
      getQuantidade,
      aumentarQuantidade,
      diminuirQuantidade,
      adicionarAoCarrinho
    }
  }
})
</script>

<style scoped>
.my-card {
  height: 100%;
  display: flex;
  flex-direction: column;
}

.my-card .q-card__actions {
  margin-top: auto;
}
</style>
