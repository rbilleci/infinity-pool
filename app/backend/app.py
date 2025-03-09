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
    app.logger.warning("acquiring connection")
    db_username = secret_data['db_username']
    db_password = secret_data['db_password']
    db_host = os.getenv("DB_HOST")
    db_port = os.getenv("DB_PORT")
    app.logger.warning("username %s", db_username)
    app.logger.warning("password %s", db_password)
    app.logger.warning("host %s", db_host)
    app.logger.warning("port %s", db_port)
    return psycopg.connect(
        host=db_host,
        port=db_port,
        user=db_username,
        password=db_password,
        dbname='postgres',
        connect_timeout=1)

def init(connection, cursor):
    # Create table and insert sample data if not exists
    app.logger.warning("initializing database")
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS greetings (
            id SERIAL PRIMARY KEY,
            message TEXT NOT NULL
        )
    """)
    # Insert the initial record if it does not exist
    app.logger.warning("selecting message")
    cursor.execute("SELECT message FROM greetings LIMIT 1")
    if not cursor.fetchone():
        app.logger.warning("inserting message")
        cursor.execute("INSERT INTO greetings (message) VALUES ('Hello World') RETURNING message")
        connection.commit()
    app.logger.warning("finished initialization")


@app.route("/", methods=["GET"])
def read_from_db():
    # See https://www.psycopg.org/psycopg3/docs/basic/usage.html
    try:
        with get_connection() as connection:
            with connection.cursor() as cursor:
                init(connection, cursor)
                app.logger.warning("selecting message")
                cursor.execute("SELECT message FROM greetings LIMIT 1")
                row = cursor.fetchone()
                return jsonify({"greeting": row[0]})
    except Exception as e:
        app.logger.warning(str(e))
        return jsonify({"error": str(e)}), 500

@app.route("/health", methods=["GET"])
def health():
    return "OK"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
