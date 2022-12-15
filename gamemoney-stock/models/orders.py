from dataConnector import dataCnctr
from utils import map_columns_data
from flask import request, make_response
import json

db_schema = 'mydb'

def get_user_orders(current_user):
    procedure = 'GET_USER_ORDERS'
    columns = ['date', 'order_type', 'price', 'amount', 'percent_done']

    data = dataCnctr.execute(db_schema, procedure, [request.args.get("coin_id"), current_user])
    result = make_response(json.dumps(map_columns_data(data, columns)), 200)
    return result

def put_user_order(current_user):
    procedure = 'PUT_USER_ORDER'
    data = request.get_json(force=True)
    params = [
        data["coin_id"],
        data["price"],
        data["amount"],
        data["order_type"],
        current_user
    ]
    data = dataCnctr.execute(db_schema, procedure, params)
    print(params)
    return make_response(json.dumps({'message': data[0][1], 'status': data[0][0]}), 200)
