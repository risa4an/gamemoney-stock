from dataConnector import dataCnctr
from utils import map_columns_data
from flask import request, make_response
import json

db_schema = 'mydb'

def get_proposals(current_user):
    procedure = 'GET_CURRENT_PROPOSALS'
    columns = ['proposal_id', 'display_name', 'proposal_text', 'price', 'game_name', 'short_name', 'promocode']

    data = dataCnctr.execute(db_schema, procedure, [current_user])

    return make_response(json.dumps(map_columns_data(data, columns)), 200)

def put_user_buy_proposal(current_user):
    procedure = 'PUT_USER_BUY_PROPOSAL'

    data = dataCnctr.execute(db_schema, procedure, [current_user, request.args.get("proposal_id")])
    return make_response(json.dumps(data), 200)
