from flask import request, make_response
from functools import wraps

def map_columns_data(data, columns):
    result = []
    for row in data:
        col_row = {}
        for i in range(len(columns)):
            col_row[columns[i]] = row[i]
        result.append(col_row)
    return result

def add_required_headers(responce):
    print(responce)
    responce.headers.add('Access-Control-Allow-Origin', '*')
    responce.headers.add('Access-Control-Allow-Headers', '*')
    responce.headers.add('Access-Control-Allow-Methods', '*')
    return responce

def add_required_headers_dec(f):
   @wraps(f)
   def decorator(*args, **kwargs):
        print('dec' + request.method)
        if request.method =='OPTIONS':
            response = make_response('', 200)
            response = add_required_headers(response)
            print(response)
            return response
        else:
            return add_required_headers(f(*args, **kwargs))
   return decorator
