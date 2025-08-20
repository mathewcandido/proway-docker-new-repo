import { store } from 'quasar/wrappers'
import { createStore } from 'vuex'
import { api } from 'boot/axios'

export default store(function (/* { ssrContext } */) {
  const Store = createStore({
    state: {
      pizzas: [],
      pedidos: [],
      carrinho: []
    },
    
    mutations: {
      setPizzas(state, pizzas) {
        state.pizzas = pizzas
      },
      setPedidos(state, pedidos) {
        state.pedidos = pedidos
      },
      adicionarAoCarrinho(state, item) {
        const itemExistente = state.carrinho.find(i => i.pizza_id === item.pizza_id)
        
        if (itemExistente) {
          itemExistente.quantidade += item.quantidade
        } else {
          state.carrinho.push(item)
        }
      },
      removerDoCarrinho(state, index) {
        state.carrinho.splice(index, 1)
      },
      limparCarrinho(state) {
        state.carrinho = []
      }
    },
    
    actions: {
      async carregarPizzas({ commit }) {
        try {
          const response = await api.get('/pizzas')
          commit('setPizzas', response.data)
        } catch (error) {
          console.error('Erro ao carregar pizzas:', error)
        }
      },
      
      async carregarPedidos({ commit }) {
        try {
          const response = await api.get('/pedidos')
          commit('setPedidos', response.data)
        } catch (error) {
          console.error('Erro ao carregar pedidos:', error)
        }
      },
      
      async enviarPedido({ commit, state }, dadosCliente) {
        try {
          const pedido = {
            cliente: dadosCliente.nome,
            endereco: dadosCliente.endereco,
            telefone: dadosCliente.telefone,
            itens: state.carrinho
          }
          
          const response = await api.post('/pedidos', pedido)
          commit('limparCarrinho')
          return response.data
        } catch (error) {
          console.error('Erro ao enviar pedido:', error)
          throw error
        }
      },
      
      async atualizarStatusPedido({ dispatch }, { pedidoId, status }) {
        try {
          await api.put(`/pedidos/${pedidoId}/status`, { status })
          dispatch('carregarPedidos')
        } catch (error) {
          console.error('Erro ao atualizar status do pedido:', error)
          throw error
        }
      }
    },
    
    getters: {
      totalCarrinho(state) {
        return state.carrinho.reduce((total, item) => {
          const pizza = state.pizzas.find(p => p.id === item.pizza_id)
          return total + (pizza ? pizza.preco * item.quantidade : 0)
        }, 0)
      }
    },
    
    modules: {
    },
    
    strict: process.env.DEBUGGING
  })

  return Store
})
