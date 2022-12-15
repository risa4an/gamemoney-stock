from flask import Flask, request, make_response
from flask_restful import Api
from utils import add_required_headers_dec
from models.coins import get_coins_list, get_coins_open_orders, get_coin_history
from models.orders import get_user_orders, put_user_order
from models.proposals import get_proposals, put_user_buy_proposal
from auth import signup_user, login_user, token_required


app = Flask(__name__)
api = Api(app)

# AUTH
@app.route('/signup', methods=['POST', 'OPTIONS'])
@add_required_headers_dec
def api_signup_user():
    return signup_user()

@app.route('/login', methods=['POST', 'OPTIONS'])
@add_required_headers_dec
def api_login_user():
    return login_user()

#COINS
@app.route('/get_coins_list', methods=['GET', 'OPTIONS'])
@add_required_headers_dec
@token_required
def api_get_coins_list(current_user):
    return get_coins_list(current_user)

@app.route('/get_coins_open_orders', methods=['GET', 'OPTIONS'])
@add_required_headers_dec
def api_get_coins_open_orders():
    return get_coins_open_orders()

@app.route('/get_coin_history', methods=['GET', 'OPTIONS'])
@add_required_headers_dec
def api_get_coin_history():
    return get_coin_history()

#ORDERS 
@app.route('/get_user_orders', methods=['GET', 'OPTIONS'])
@add_required_headers_dec
@token_required
def api_get_user_orders(current_user):
    return get_user_orders(current_user)

@app.route('/put_user_order', methods=['PUT', 'OPTIONS'])
@add_required_headers_dec
@token_required
def api_put_user_order(current_user):
    return put_user_order(current_user)

#PROPOSALS
@app.route('/get_proposals', methods=['GET', 'OPTIONS'])
@add_required_headers_dec
@token_required
def api_get_proposals(current_user):
    return get_proposals(current_user)

@app.route('/put_proposal', methods=['GET', 'OPTIONS'])
@add_required_headers_dec
@token_required
def api_put_proposal(current_user):
    return put_user_buy_proposal(current_user)

if __name__ == '__main__':
    app.run(debug=True)