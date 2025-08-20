const routes = [
  {
    path: '/',
    component: () => import('layouts/MainLayout.vue'),
    children: [
      { path: '', component: () => import('pages/Index.vue') },
      { path: 'cardapio', component: () => import('pages/Cardapio.vue') },
      { path: 'pedido', component: () => import('pages/NovoPedido.vue') },
      { path: 'pedidos', component: () => import('pages/Pedidos.vue') },
      { path: 'admin', component: () => import('pages/Admin.vue') }
    ]
  },

  // Rota para página não encontrada
  {
    path: '/:catchAll(.*)*',
    component: () => import('pages/Error404.vue')
  }
]

export default routes
