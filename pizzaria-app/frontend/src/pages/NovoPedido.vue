<template>
  <q-page padding>
    <h1 class="text-h4 text-center q-mb-lg">Meu Pedido</h1>
    
    <div v-if="carrinho.length === 0" class="text-center q-pa-xl">
      <q-icon name="shopping_cart" size="5rem" color="grey-5" />
      <p class="text-h6 text-grey-7 q-mt-md">Seu carrinho está vazio</p>
      <q-btn color="primary" label="Ver Cardápio" icon="restaurant_menu" to="/cardapio" class="q-mt-md" />
    </div>
    
    <div v-else>
      <q-list bordered separator>
        <q-item v-for="(item, index) in carrinhoComDetalhes" :key="index">
          <q-item-section>
            <q-item-label>{{ item.nome }}</q-item-label>
            <q-item-label caption>{{ item.ingredientes }}</q-item-label>
          </q-item-section>
          
          <q-item-section side>
            <div class="row items-center">
              <q-btn flat round color="negative" icon="remove" @click="diminuirQuantidade(index)" />
              <span class="q-mx-sm">{{ item.quantidade }}</span>
              <q-btn flat round color="positive" icon="add" @click="aumentarQuantidade(index)" />
            </div>
          </q-item-section>
          
          <q-item-section side>
            <div class="text-subtitle1">
              R$ {{ (item.preco * item.quantidade).toFixed(2) }}
            </div>
          </q-item-section>
          
          <q-item-section side>
            <q-btn flat round color="negative" icon="delete" @click="removerItem(index)" />
          </q-item-section>
        </q-item>
      </q-list>
      
      <div class="text-right q-mt-md">
        <div class="text-h6">Total: R$ {{ totalCarrinho.toFixed(2) }}</div>
      </div>
      
      <q-separator class="q-my-lg" />
      
      <h2 class="text-h5 q-mb-md">Dados para entrega</h2>
      
      <q-form @submit="finalizarPedido" class="q-gutter-md">
        <q-input
          filled
          v-model="cliente.nome"
          label="Nome completo *"
          :rules="[val => !!val || 'Nome é obrigatório']"
        />
        
        <q-input
          filled
          v-model="cliente.telefone"
          label="Telefone *"
          mask="(##) #####-####"
          :rules="[val => !!val || 'Telefone é obrigatório']"
        />
        
        <q-input
          filled
          v-model="cliente.endereco"
          label="Endereço completo *"
          type="textarea"
          :rules="[val => !!val || 'Endereço é obrigatório']"
        />
        
        <q-input
          filled
          v-model="cliente.observacoes"
          label="Observações"
          type="textarea"
        />
        
        <div class="row justify-end q-mt-md">
          <q-btn label="Limpar Carrinho" color="negative" flat class="q-mr-sm" @click="limparCarrinho" />
          <q-btn label="Finalizar Pedido" type="submit" color="primary" />
        </div>
      </q-form>
    </div>
  </q-page>
</template>

<script>
import { defineComponent, ref, computed } from 'vue'
import { useStore } from 'vuex'
import { useQuasar } from 'quasar'
import { useRouter } from 'vue-router'

export default defineComponent({
  name: 'PageNovoPedido',
  
  setup() {
    const store = useStore()
    const $q = useQuasar()
    const router = useRouter()
    
    const cliente = ref({
      nome: '',
      telefone: '',
      endereco: '',
      observacoes: ''
    })
    
    const carrinho = computed(() => store.state.carrinho)
    const totalCarrinho = computed(() => store.getters.totalCarrinho)
    
    const carrinhoComDetalhes = computed(() => {
      return carrinho.value.map(item => {
        const pizza = store.state.pizzas.find(p => p.id === item.pizza_id)
        return {
          ...pizza,
          quantidade: item.quantidade
        }
      })
    })
    
    const aumentarQuantidade = (index) => {
      const item = { ...carrinho.value[index] }
      item.quantidade += 1
      store.commit('removerDoCarrinho', index)
      store.commit('adicionarAoCarrinho', item)
    }
    
    const diminuirQuantidade = (index) => {
      const item = { ...carrinho.value[index] }
      if (item.quantidade > 1) {
        item.quantidade -= 1
        store.commit('removerDoCarrinho', index)
        store.commit('adicionarAoCarrinho', item)
      } else {
        removerItem(index)
      }
    }
    
    const removerItem = (index) => {
      store.commit('removerDoCarrinho', index)
    }
    
    const limparCarrinho = () => {
      $q.dialog({
        title: 'Confirmar',
        message: 'Tem certeza que deseja limpar o carrinho?',
        cancel: true,
        persistent: true
      }).onOk(() => {
        store.commit('limparCarrinho')
      })
    }
    
    const finalizarPedido = async () => {
      try {
        $q.loading.show({
          message: 'Enviando seu pedido...'
        })
        
        await store.dispatch('enviarPedido', cliente.value)
        
        $q.loading.hide()
        
        $q.notify({
          color: 'positive',
          textColor: 'white',
          icon: 'check_circle',
          message: 'Pedido realizado com sucesso!'
        })
        
        router.push('/pedidos')
      } catch (error) {
        $q.loading.hide()
        
        $q.notify({
          color: 'negative',
          textColor: 'white',
          icon: 'error',
          message: 'Erro ao enviar pedido. Tente novamente.'
        })
      }
    }
    
    return {
      cliente,
      carrinho,
      carrinhoComDetalhes,
      totalCarrinho,
      aumentarQuantidade,
      diminuirQuantidade,
      removerItem,
      limparCarrinho,
      finalizarPedido
    }
  }
})
</script>
