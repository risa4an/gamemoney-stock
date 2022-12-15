from dataConnector import dataCnctr
from utils import map_columns_data, add_required_headers
from flask import request, make_response
import json


db_schema = 'mydb'

def get_coins_list(current_user):
    procedure = 'GET_COINS_LIST'
    print(request.method)
    columns = ['currency_id', 'display_name', 'short_name', 'exchange_rate', 'amount']
    data = dataCnctr.execute(db_schema, procedure, [current_user])
    data = json.dumps(map_columns_data(data, columns))
    response = make_response(data, 200)
    return response
    
def get_coins_open_orders():
    args = request.args
    coin_id = args.get("coin_id")
    print(request.method)
    procedure = 'GET_COINS_OPEN_ORDERS'
    columns = ['price', 'amount', 'block_num']
    data = dataCnctr.execute(db_schema, procedure, [coin_id])
    result = {
        'red': [],
        'white': [],
        'green': [] 
    }
    data = map_columns_data(data, columns)
    for row in data:
        if row['block_num'] == 1:
            result['red'].append(row)
        elif row['block_num'] == 0:
            result['white'].append(row)
        else:
            result['green'].append(row)
    data = json.dumps(result)
    response = make_response(data, 200)
    return response

def get_coin_history():
    coin_id = request.args.get("coin_id")

    procedure = 'GET_COIN_HISTORY'
    data = dataCnctr.execute(db_schema, procedure, [coin_id])
    columns = ['x', 'y']
    # result = {
    #     'display_time': [],
    #     'values': []
    # }
    # for row in data[::-1]:
    #     result['display_time'].append(row[0])
    #     result['values'].append(row[1])
    return make_response(json.dumps(map_columns_data(data, columns)), 200)

        
    