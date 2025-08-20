<template>
  <q-page padding>
    <h1 class="text-h4 text-center q-mb-lg">Administração de Pedidos</h1>
    
    <div v-if="pedidos.length === 0" class="text-center q-pa-xl">
      <q-icon name="receipt" size="5rem" color="grey-5" />
      <p class="text-h6 text-grey-7 q-mt-md">Não há pedidos registrados</p>
    </div>
    
    <div v-else>
      <q-table
        title="Pedidos"
        :rows="pedidos"
        :columns="columns"
        row-key="id"
        :pagination="{ rowsPerPage: 10 }"
      >
        <template v-slot:body="props">
          <q-tr :props="props">
            <q-td key="id" :props="props">
              {{ props.row.id }}
            </q-td>
            <q-td key="data" :props="props">
              {{ props.row.data }}
            </q-td>
            <q-td key="cliente" :props="props">
              {{ props.row.cliente }}
            </q-td>
            <q-td key="total" :props="props">
              R$ {{ props.row.total.toFixed(2) }}
            </q-td>
            <q-td key="status" :props="props">
              <q-chip :color="getStatusColor(props.row.status)" text-color="white">
                {{ props.row.status }}
              </q-chip>
            </q-td>
            <q-td key="acoes" :props="props">
              <q-btn-dropdown color="primary" label="Atualizar Status">
                <q-list>
                  <q-item clickable v-close-popup @click="atualizarStatus(props.row.id, 'Recebido')">
                    <q-item-section>
                      <q-item-label>Recebido</q-item-label>
                    </q-item-section>
                  </q-item>
                  
                  <q-item clickable v-close-popup @click="atualizarStatus(props.row.id, 'Em preparo')">
                    <q-item-section>
                      <q-item-label>Em preparo</q-item-label>
                    </q-item-section>
                  </q-item>
                  
                  <q-item clickable v-close-popup @click="atualizarStatus(props.row.id, 'Saiu para entrega')">
                    <q-item-section>
                      <q-item-label>Saiu para entrega</q-item-label>
                    </q-item-section>
                  </q-item>
                  
                  <q-item clickable v-close-popup @click="atualizarStatus(props.row.id, 'Entregue')">
                    <q-item-section>
                      <q-item-label>Entregue</q-item-label>
                    </q-item-section>
                  </q-item>
                  
                  <q-item clickable v-close-popup @click="atualizarStatus(props.row.id, 'Cancelado')">
                    <q-item-section>
                      <q-item-label>Cancelado</q-item-label>
                    </q-item-section>
                  </q-item>
                </q-list>
              </q-btn-dropdown>
              
              <q-btn flat round color="info" icon="visibility" @click="verDetalhes(props.row)" />
            </q-td>
          </q-tr>
        </template>
      </q-table>
    </div>
    
    <q-dialog v-model="detalhesPedidoDialog">
      <q-card style="min-width: 350px">
        <q-card-section>
          <div class="text-h6">Detalhes do Pedido #{{ pedidoSelecionado?.id }}</div>
        </q-card-section>

        <q-card-section v-if="pedidoSelecionado">
          <div class="q-mb-md">
            <div class="text-subtitle1">Dados do Cliente</div>
            <p><strong>Nome:</strong> {{ pedidoSelecionado.cliente }}</p>
            <p><strong>Telefone:</strong> {{ pedidoSelecionado.telefone }}</p>
            <p><strong>Endereço:</strong> {{ pedidoSelecionado.endereco }}</p>
          </div>
          
          <div class="q-mb-md">
            <div class="text-subtitle1">Itens do Pedido</div>
            <q-list dense>
              <q-item v-for="(item, index) in getItensPedido(pedidoSelecionado)" :key="index">
                <q-item-section>
                  <q-item-label>{{ item.quantidade }}x {{ item.nome }}</q-item-label>
                </q-item-section>
                <q-item-section side>
                  R$ {{ (item.preco * item.quantidade).toFixed(2) }}
                </q-item-section>
              </q-item>
            </q-list>
          </div>
          
          <div class="text-right">
            <div class="text-subtitle1">Total: R$ {{ pedidoSelecionado.total.toFixed(2) }}</div>
          </div>
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="Fechar" color="primary" v-close-popup />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script>
import { defineComponent, ref, computed, onMounted } from 'vue'
import { useStore } from 'vuex'
import { useQuasar } from 'quasar'

export default defineComponent({
  name: 'PageAdmin',
  
  setup() {
    const store = useStore()
    const $q = useQuasar()
    
    const columns = [
      { name: 'id', align: 'left', label: 'ID', field: 'id', sortable: true },
      { name: 'data', align: 'left', label: 'Data', field: 'data', sortable: true },
      { name: 'cliente', align: 'left', label: 'Cliente', field: 'cliente', sortable: true },
      { name: 'total', align: 'right', label: 'Total', field: 'total', sortable: true },
      { name: 'status', align: 'center', label: 'Status', field: 'status', sortable: true },
      { name: 'acoes', align: 'center', label: 'Ações', field: 'acoes' }
    ]
    
    const detalhesPedidoDialog = ref(false)
    const pedidoSelecionado = ref(null)
    
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
          return 'blue'
        case 'Em preparo':
          return 'orange'
        case 'Saiu para entrega':
          return 'purple'
        case 'Entregue':
          return 'positive'
        case 'Cancelado':
          return 'negative'
        default:
          return 'grey'
      }
    }
    
    const atualizarStatus = async (pedidoId, status) => {
      try {
        $q.loading.show({
          message: 'Atualizando status...'
        })
        
        await store.dispatch('atualizarStatusPedido', { pedidoId, status })
        
        $q.loading.hide()
        
        $q.notify({
          color: 'positive',
          textColor: 'white',
          icon: 'check_circle',
          message: 'Status atualizado com sucesso!'
        })
      } catch (error) {
        $q.loading.hide()
        
        $q.notify({
          color: 'negative',
          textColor: 'white',
          icon: 'error',
          message: 'Erro ao atualizar status. Tente novamente.'
        })
      }
    }
    
    const verDetalhes = (pedido) => {
      pedidoSelecionado.value = pedido
      detalhesPedidoDialog.value = true
    }
    
    return {
      columns,
      pedidos,
      getStatusColor,
      atualizarStatus,
      verDetalhes,
      detalhesPedidoDialog,
      pedidoSelecionado,
      getItensPedido
    }
  }
})
</script>
