import mysql.connector

class DataConnector:
    def __init__(self):
        self._connection = mysql.connector.pooling.MySQLConnectionPool(pool_name = "mypool", 
            pool_size = 20,
            pool_reset_session=True,
            host="127.0.0.1",
            port=3306,
            user="root",
            password="26.10Kate")

    def __prepare_ex_str(self, schema, procedure, params):
        ex_str = "CALL " + schema + "." + procedure
        if params is not None:
            ex_str = ex_str + "("
            for p in params:
                if p is not None:
                    if isinstance(p, str):
                        ex_str = ex_str + "'" + p + "', "
                    else: 
                        ex_str = ex_str + str(p) + ", "
                else:
                    ex_str = ex_str + 'NULL, '
            ex_str = ex_str[:len(ex_str) - 2] + ')'
        ex_str = ex_str + ';'
        return ex_str


    def execute(self, schema, procedure, params=None):
        ex_str = self.__prepare_ex_str(schema, procedure, params)
            
        connection = self._connection.get_connection()
        cur = connection.cursor()
                # Execute a query
        cur.execute(ex_str)

        result_data = []
        for row in cur:
            result_data.append(row)
        cur.close()
        self._connection.add_connection(connection.reconnect())
                
        return result_data
            

dataCnctr = DataConnector()


