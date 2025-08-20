from flask import Flask, jsonify, request
from flask_cors import CORS
import os
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Dados simulados para a aplicação
pizzas = [
    {
        "id": 1, 
        "nome": "Margherita", 
        "ingredientes": "Molho de tomate, mussarela, manjericão", 
        "preco": 35.90,
        "imagem": "https://images.unsplash.com/photo-1604068549290-dea0e4a305ca?q=80&w=400&auto=format&fit=crop"
    },
    {
        "id": 2, 
        "nome": "Calabresa", 
        "ingredientes": "Molho de tomate, mussarela, calabresa, cebola", 
        "preco": 39.90,
        "imagem": "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?q=80&w=400&auto=format&fit=crop"
    },
    {
        "id": 3, 
        "nome": "Quatro Queijos", 
        "ingredientes": "Molho de tomate, mussarela, provolone, gorgonzola, parmesão", 
        "preco": 45.90,
        "imagem": "https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=400&auto=format&fit=crop"
    },
    {
        "id": 4, 
        "nome": "Portuguesa", 
        "ingredientes": "Molho de tomate, mussarela, presunto, ovos, cebola, ervilha", 
        "preco": 42.90,
        "imagem": "https://images.unsplash.com/photo-1593560708920-61dd98c46a4e?q=80&w=400&auto=format&fit=crop"
    },
    {
        "id": 5, 
        "nome": "Frango com Catupiry", 
        "ingredientes": "Molho de tomate, mussarela, frango desfiado, catupiry", 
        "preco": 43.90,
        "imagem": "https://images.unsplash.com/photo-1571407970349-bc81e7e96d47?q=80&w=400&auto=format&fit=crop"
    },
    {
        "id": 6, 
        "nome": "Pepperoni", 
        "ingredientes": "Molho de tomate, mussarela, pepperoni", 
        "preco": 42.90,
        "imagem": "https://images.unsplash.com/photo-1628840042765-356cda07504e?q=80&w=400&auto=format&fit=crop"
    }
]

pedidos = []

@app.route('/api/pizzas', methods=['GET'])
def get_pizzas():
    return jsonify(pizzas)

@app.route('/api/pizzas/<int:pizza_id>', methods=['GET'])
def get_pizza(pizza_id):
    pizza = next((p for p in pizzas if p["id"] == pizza_id), None)
    if pizza:
        return jsonify(pizza)
    return jsonify({"error": "Pizza não encontrada"}), 404

@app.route('/api/pedidos', methods=['GET'])
def get_pedidos():
    return jsonify(pedidos)

@app.route('/api/pedidos', methods=['POST'])
def create_pedido():
    data = request.json
    
    # Validação básica
    if not data or 'itens' not in data or not data['itens']:
        return jsonify({"error": "Dados inválidos"}), 400
    
    # Criar novo pedido
    novo_pedido = {
        "id": len(pedidos) + 1,
        "data": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "itens": data['itens'],
        "cliente": data.get('cliente', 'Cliente não identificado'),
        "endereco": data.get('endereco', 'Retirada no local'),
        "telefone": data.get('telefone', 'Não informado'),
        "status": "Recebido",
        "total": sum(next((p['preco'] for p in pizzas if p['id'] == item['pizza_id']), 0) * item['quantidade'] 
                    for item in data['itens'])
    }
    
    pedidos.append(novo_pedido)
    return jsonify(novo_pedido), 201

@app.route('/api/pedidos/<int:pedido_id>/status', methods=['PUT'])
def update_status(pedido_id):
    data = request.json
    pedido = next((p for p in pedidos if p["id"] == pedido_id), None)
    
    if not pedido:
        return jsonify({"error": "Pedido não encontrado"}), 404
    
    if 'status' not in data:
        return jsonify({"error": "Status não informado"}), 400
    
    pedido['status'] = data['status']
    return jsonify(pedido)

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
