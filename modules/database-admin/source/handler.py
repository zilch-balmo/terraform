from boto3 import Session
from psycopg2 import connect


def find_rds_address(session):
    rds = session.client("rds")

    response = rds.describe_db_instances(
        DBInstanceIdentifier="zilch",
    )

    return next(
        db_instance
        for db_instance in response["DBInstances"]
    )["Endpoint"]["Address"]


def find_rds_master_password(session):
    secretsmanager = session.client("secretsmanager")

    response = secretsmanager.get_secret_value(
        SecretId="rds_master_password",
    )
    return response["SecretString"]


def list_databases(**kwargs):
    with connect(**kwargs) as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT datname FROM pg_database WHERE datistemplate = false;")
            for name, *_ in cursor.fetchall():
                print(name)


def main(event, context):
    """
    Handler function.

    """
    session = Session()

    host = find_rds_address(session)
    password = find_rds_master_password(session)

    list_databases(
        dbname="postgres",
        user="postgres",
        password=password,
        host=host,
    )
