<template>
  <q-page padding>
    <h1 class="text-h4 text-center q-mb-lg">Meus Pedidos</h1>
    
    <div v-if="pedidos.length === 0" class="text-center q-pa-xl">
      <q-icon name="receipt" size="5rem" color="grey-5" />
      <p class="text-h6 text-grey-7 q-mt-md">Você ainda não fez nenhum pedido</p>
      <q-btn color="primary" label="Fazer Pedido" icon="shopping_cart" to="/cardapio" class="q-mt-md" />
    </div>
    
    <div v-else>
      <q-list bordered separator>
        <q-expansion-item
          v-for="pedido in pedidos"
          :key="pedido.id"
          :label="`Pedido #${pedido.id} - ${pedido.data}`"
          :caption="`Status: ${pedido.status} | Total: R$ ${pedido.total.toFixed(2)}`"
          expand-separator
          :header-class="getStatusColor(pedido.status)"
        >
          <q-card>
            <q-card-section>
              <div class="text-h6">Dados do Cliente</div>
              <div class="q-ml-md">
                <p><strong>Nome:</strong> {{ pedido.cliente }}</p>
                <p><strong>Telefone:</strong> {{ pedido.telefone }}</p>
                <p><strong>Endereço:</strong> {{ pedido.endereco }}</p>
              </div>
              
              <div class="text-h6 q-mt-md">Itens do Pedido</div>
              <q-list dense>
                <q-item v-for="(item, index) in getItensPedido(pedido)" :key="index">
                  <q-item-section>
                    <q-item-label>{{ item.quantidade }}x {{ item.nome }}</q-item-label>
                    <q-item-label caption>{{ item.ingredientes }}</q-item-label>
                  </q-item-section>
                  <q-item-section side>
                    R$ {{ (item.preco * item.quantidade).toFixed(2) }}
                  </q-item-section>
                </q-item>
              </q-list>
              
              <div class="text-right q-mt-md">
                <div class="text-h6">Total: R$ {{ pedido.total.toFixed(2) }}</div>
              </div>
            </q-card-section>
          </q-card>
        </q-expansion-item>
      </q-list>
    </div>
  </q-page>
</template>

<script>
import { defineComponent, computed, onMounted } from 'vue'
import { useStore } from 'vuex'

export default defineComponent({
  name: 'PagePedidos',
  
  setup() {
    const store = useStore()
    
    onMounted(() => {
      store.dispatch('carregarPizzas')
      store.dispatch('carregarPedidos')
    })
    
    const pedidos = computed(() => store.state.pedidos)
    
    const getItensPedido = (pedido) => {
      return pedido.itens.map(item => {
        const pizza = store.state.pizzas.find(p => p.id === item.pizza_id)
        return {
          ...pizza,
          quantidade: item.quantidade
        }
      })
    }
    
    const getStatusColor = (status) => {
      switch (status) {
        case 'Recebido':
          return 'text-blue'
        case 'Em preparo':
          return 'text-orange'
        case 'Saiu para entrega':
          return 'text-purple'
        case 'Entregue':
          return 'text-positive'
        case 'Cancelado':
          return 'text-negative'
        default:
          return ''
      }
    }
    
    return {
      pedidos,
      getItensPedido,
      getStatusColor
    }
  }
})
</script>
