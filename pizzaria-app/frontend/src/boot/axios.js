import { boot } from 'quasar/wrappers'
import axios from 'axios'

// Configuração do axios para apontar para o backend
const api = axios.create({ 
  baseURL: process.env.NODE_ENV === 'development' 
    ? 'http://localhost:5000/api' 
    : '/api'
})

export default boot(({ app }) => {
  app.config.globalProperties.$axios = axios
  app.config.globalProperties.$api = api
})

export { api }
