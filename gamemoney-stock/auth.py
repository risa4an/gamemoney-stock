import jwt
import json 
from functools import wraps
from flask import request, make_response
import string
import secrets
from werkzeug.security import generate_password_hash,check_password_hash
from dataConnector import dataCnctr
import datetime
from utils import add_required_headers

SECRET_KEY = '004f2af45d3a4e161a7dd2d17fdae47f'
alphabet = string.ascii_letters + string.digits

def token_required(f):
   @wraps(f)
   def decorator(*args, **kwargs):
       token = None
       if 'x-access-tokens' in request.headers:
           token = request.headers['x-access-tokens']
 
       if not token:
           return make_response(json.dumps({'message': 'a valid token is missing'}), 200)
       try:
           data = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
           current_user = data['public_id']
       except:
           return make_response(json.dumps({'message': 'token is invalid'}), 200)
 
       return f(current_user, *args, **kwargs)
   return decorator

def signup_user(): 
    data = request.get_json(force=True) 
    
    sault = ''.join(secrets.choice(alphabet) for i in range(10))
    hashed_password = generate_password_hash(data['password'] + sault, method='sha256')
    response = dataCnctr.execute('mydb', 'PUT_NEW_USER', [
        data['username'], hashed_password, sault, sault])  
    print(data['username'], hashed_password, sault, sault)
    print(response)
    if len(response) == 0:
        result = json.dumps({'message': 'registered successfully'})
    elif 'email' in response[0][0]:
        result = json.dumps({'message': 'this email is already registered'})
    else:
        result = json.dumps({'message': 'error'})
    result = make_response(result, 200)
    return result

def login_user():
    auth = request.get_json(force=True)
    if not auth or not auth['username'] or not auth['password']: 
       return make_response('could not verify', 401, {'Authentication': 'login required"'})   
 
    query = dataCnctr.execute('mydb', 'GET_USER_BY_EMAIL', [auth['username']]) 
    if len(query) == 0:
        return make_response('could not verify', 401, {'Authentication': 'uknown email"'})

    if check_password_hash(query[0][1], auth['password'] + query[0][2]):
        token = jwt.encode({'public_id' : query[0][0], 'exp' : datetime.datetime.utcnow() + datetime.timedelta(minutes=45)}, SECRET_KEY, "HS256")
        responce = make_response({'access' : token}, 200)
        return responce
 
    return make_response('could not verify',  401, {'Authentication': 'login required'})

