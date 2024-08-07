# Local Database for testing service ✨

## Requirements

- docker
- docker-compose

## Deploy the solution locally

Steps:
1. Cd to this folder (local/db)
2. docker-compose up

To kill the container press `ctrl+c`, or to terminate the solution run `docker-compose down` (duh 😂) from another terminal.

## Bootstrap the database
For Bootstrapping the database first you will need to connect through a db client (like dbeaver)

Once your solution is deployed to connect to the Database just use these configuration:
```
host=localhost
port=5432
username=postgres_user
password=postgres_password
database=postgres
```

Once connected, fire up an empty sql script page, and apply the database schema available from here:  
**https://bitbucket.org/storm_rfa/siae-valorizzatore-database-infra/src/dev/sql/schema-db-valorizzatore.sql**


## Connect the service to the database

Configure the database connection to use the following parameters when connecting from local stage
```
host=localhost
port=5432
username=postgres_user
password=postgres_password
database=postgres
```

Remember to **run your container first 😛**