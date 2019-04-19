from json import loads

from boto3 import Session
from psycopg2 import connect, ProgrammingError


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


def find_service_password(session, service):
    secretsmanager = session.client("secretsmanager")

    response = secretsmanager.get_secret_value(
        SecretId=f"secrets//{service}",
    )
    data = loads(response["SecretString"])
    return data["config"]["postgres"]["password"]


def list_databases(**kwargs):
    with connect(**kwargs) as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT datname FROM pg_database WHERE datistemplate = false;")
            return [
                name
                for name, *_ in cursor.fetchall()
            ]


def create_database(service, service_password, **kwargs):
    with connect(**kwargs) as connection:
        with connection.cursor() as cursor:
            # turn off transactions; CREATE DATABASE cannot run within a transaction
            connection.autocommit = True

            # create the service role (user) with the login password
            try:
                cursor.execute(f"CREATE ROLE {service} WITH LOGIN PASSWORD '{service_password}';")
            except ProgrammingError as error:
                # ok if duplicate_object
                if error.pgcode != "42710":
                    raise

            # grant the service role to the master user
            cursor.execute(f"GRANT {service} TO {kwargs['user']}")

            # create the database, owned by the service role
            try:
                cursor.execute(f"CREATE DATABASE {service}_db WITH OWNER {service};")
            except ProgrammingError as error:
                print(error.pgcode)
                # ok if duplicate_database
                if error.pgcode != "42P04":
                    raise


def drop_database(service, **kwargs):
    with connect(**kwargs) as connection:
        with connection.cursor() as cursor:
            # turn off transactions; DROP DATABASE cannot run within a transaction
            connection.autocommit = True
            cursor.execute(f"DROP DATABASE IF EXISTS {service}_db;")
            cursor.execute(f"DROP ROLE IF EXISTS {service};")



def main(event, context):
    """
    Handler function.

    """
    session = Session()

    host = find_rds_address(session)
    password = find_rds_master_password(session)

    kwargs = dict(
        dbname="postgres",
        user="postgres",
        password=password,
        host=host,
    )

    action = event.get("action", "list")

    if action == "create":
        # create
        service = event["service"]
        service_password = find_service_password(session, service)
        create_database(service, service_password, **kwargs)
        return dict(service=service)

    if action == "drop":
        # drop
        service = event["service"]
        drop_database(service, **kwargs)
        return dict(service=service)

    else:
        # list
        items = list_databases(**kwargs)
        return dict(items=items)
