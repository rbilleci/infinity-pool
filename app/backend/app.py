from flask import Flask, jsonify
import os
import psycopg
import json
import boto3


# fetch the secrets
secrets_client = boto3.client('secretsmanager')
secret_data = json.loads(secrets_client.get_secret_value(SecretId='db-credentials')['SecretString'])

app = Flask(__name__)

def get_connection():
    db_username = secret_data['db_username']
    db_password = secret_data['db_password']
    db_host = os.getenv("DB_HOST")
    db_port = os.getenv("DB_PORT")
    return psycopg.connect(host=db_host, port=db_port, user=db_username, password=db_password, dbname='postgres')

def init(connection, cursor):
    # Create table and insert sample data if not exists
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS greetings (
            id SERIAL PRIMARY KEY,
            message TEXT NOT NULL
        )
    """)
    # Insert the initial record if it does not exist
    cursor.execute("SELECT message FROM greetings LIMIT 1")
    if not cursor.fetchone():
        cursor.execute("INSERT INTO greetings (message) VALUES ('Hello World') RETURNING message")
        connection.commit()


@app.route("/", methods=["GET"])
def read_from_db():
    # See https://www.psycopg.org/psycopg3/docs/basic/usage.html
    try:
        with get_connection() as connection:
            with connection.cursor() as cursor:
                init(connection, cursor)
                cursor.execute("SELECT message FROM greetings LIMIT 1")
                row = cursor.fetchone()
                return jsonify({"greeting": row[0]})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    print("starting backend")
    print(secret_data)
    app.run(host="0.0.0.0", port=80)
