# database-admin

Lambda function to administer PostgreSQL on RDS.

When running services via ECS with Fargate and reasonable network security, there is no
natural place from which to run PostgreSQL administration commands, especially for the
commands required to provisione new databases and roles.

This module creates a Lambda function that runs these provisioning functions via a custom
version of [psycopg2](https://github.com/pzmosquito/awslambda-psycopg2).


## Features

 - List databases
 - Create database and role
 - Remove database and role
