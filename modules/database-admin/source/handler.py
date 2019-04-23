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
        SecretId=f"rds_{service}_password",
    )
    return response["SecretString"]


def list_databases(**kwargs):
    with connect(**kwargs) as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT datname FROM pg_database WHERE datistemplate = false;")
            return [
                name
                for name, *_ in cursor.fetchall()
            ]


def list_tables(**kwargs):
    with connect(**kwargs) as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';")
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


def create_alembic_table(**kwargs):
    with connect(**kwargs) as connection:
        with connection.cursor() as cursor:
            connection.autocommit = True
            try:
                cursor.execute("CREATE TABLE IF NOT EXISTS alembic_version (version_num character varying(32) not null, constraint alembic_version_pkc primary key(version_num));")
            except ProgrammingError as error:
                print(error.pgcode)


def drop_database(service, **kwargs):
    with connect(**kwargs) as connection:
        with connection.cursor() as cursor:
            # turn off transactions; DROP DATABASE cannot run within a transaction
            connection.autocommit = True
            cursor.execute(f"DROP DATABASE IF EXISTS {service}_db;")
            cursor.execute(f"DROP OWNED BY {service}");
            cursor.execute(f"DROP ROLE IF EXISTS {service};")


def get_service_info(session, event):
    service = event["service"]
    service_password = find_service_password(session, service)
    return service, service_password


def main(event, context):
    """
    Handler function.

    """
    session = Session()

    host = find_rds_address(session)
    password = find_rds_master_password(session)

    kwargs = dict(
        user="postgres",
        password=password,
    )

    action = event.get("action", "list_databases")

    if action == "create":
        # create
        service, service_password = get_service_info(session, event)
        create_database(service, service_password, dbname="postgres", host=host, **kwargs)
        create_alembic_table(user=service, password=service_password, dbname=f"{service}_db", host=host)
        return dict(service=service)

    elif action == "list_tables":
        # list_tables
        service, service_password = get_service_info(session, event)
        items = list_tables(user=service, password=service_password, dbname=f"{service}_db", host=host)
        return dict(items=items)

    elif action == "drop":
        # drop
        service = event["service"]
        drop_database(service, dbname="postgres", host=host, **kwargs)
        return dict(service=service)

    else:
        # list_databases
        items = list_databases(dbname="postgres", host=host, **kwargs)
        return dict(items=items)
