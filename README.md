- [What](#org1a63d55)
- [Why](#org2d3feb5)
- [How](#orgfa79a10)
- [Part A:  At the Command Line](#org44dafec)
  - [Step 1:  Create a new directory.](#org85a2b70)
  - [Step 2:  Create a PostgreSQL initialization directory.](#org99b1afa)
  - [Step 3:  Download the PostgresSQL initialization files.](#orgc45ffb3)
  - [Step 4:  Scaffold the Docker Compose file.](#org271c99c)
  - [Step 5:  Add the `postgres` service.](#org5d4cc79)
  - [Step 7:  Test the PostgreSQL service.](#orgdae680e)
  - [Step 8:  Create a MongoDB initialization directory.](#orgc1653e0)
  - [Step 9:  Download the MongoDB initialization files.](#org5063eee)
  - [Step 10:  Add the `mongo` service.](#org47d2a45)
  - [Step 12:  Test the MongoDB service.](#org69a9b48)
  - [Step 13:  Add the `mongo_data_connector` service.](#org0c80fc5)
  - [Step 14:  Add the `redis` service.](#orgaefc138)
  - [Step 15:  Add Hasura.](#org98e1036)
  - [Step 16:  Set environment variables.](#orgcf4b6a0)
  - [Step 17:  Start the `mongo_data_connector`, `redis` and `hasura` services.](#org17c83bb)
  - [Step 18:  Open the Hasura Console and log in.](#org901bd2e)
- [Part B:  In Hasura Console](#org3d63861)



<a id="org1a63d55"></a>

# What

This project comprises instructions for setting up heterogeneous data sources with Hasura v2.


<a id="org2d3feb5"></a>

# Why

There can never be too many tutorials, walk-throughs, and lighted pathways for setting up Hasura. This is yet another one.


<a id="orgfa79a10"></a>

# How

This project uses Docker Compose to launch services for PostgreSQL, for MongoDB, for Redis, for Hasura, and for a Hasura Data Connector. It also relies on a handful of environment variables to be supplied by the user. As a tutorial, it is divided into two parts: Part A and Part B.

Part A offers a sequence of steps to be performed at the Command Line and optionally in a text editor, to create a Docker Compose file and to acquire suppporting initialization files to create the services.

Part B offers a sequence of steps to be performed in Hasura Console once all the services have been launched.


<a id="org44dafec"></a>

# Part A:  At the Command Line


<a id="org85a2b70"></a>

## Step 1:  Create a new directory.

Create a directory to work in and move to it.

```bash
rm -rf scratch
mkdir -p scratch
cd scratch
```

-   **What did this do?:** This step just creates a scratch workspace for the project.


<a id="org99b1afa"></a>

## Step 2:  Create a PostgreSQL initialization directory.

Create a directory to mount into the PostgreSQL container in order to initialize the database.

```bash
mkdir -p initdb.d-postgres
```

-   **What did this do?:** This step creates a directory that will be mounted into the PostgreSQL container as a volume, in a special directory that the container image uses to access initialization files.


<a id="orgc45ffb3"></a>

## Step 3:  Download the PostgresSQL initialization files.

Download PostgreSQL initialization scripts into its initialization directory.

```bash
wget -O initdb.d-postgres/03_chinook_database.sql https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-postgres/03_chinook_database.sql
wget -O initdb.d-postgres/04_chinook_ddl.sql https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-postgres/04_chinook_ddl.sql
wget -O initdb.d-postgres/05_chinook_dml.sql https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-postgres/05_chinook_dml.sql
```

-   **What did this do?:** This step downloaded PostgreSQL SQL initialization files from this GitHub repository, with DDL and DML for the Chinook sample database.


<a id="org271c99c"></a>

## Step 4:  Scaffold the Docker Compose file.

Use a code editor to start the Docker Compose file with its preamble.

```yaml
version: '3.1'
services:
```

Alternatively, add to the file from the command line.

```bash
cat <<'EOF' > docker-compose.yaml
version: '3.1'
services:
EOF
```

-   **What did this do?:** This step added the Docker Compose preamble to the `docker-compose.yaml` file to set the version and create the `services` node.


<a id="org5d4cc79"></a>

## Step 5:  Add the `postgres` service.

Use a code editor to add a stanza for the `postgres` service.

```yaml
postgres:
  image: postgres:16          # Use a modern version of PostgreSQL.
  environment:                # Set its superuser username and password.
    POSTGRES_PASSWORD: postgres
  volumes:                    # Initialize from the contents of the initialization directory.
    - ./initdb.d-postgres:/docker-entrypoint-initdb.d:ro
  healthcheck:                # Use a sensible healthcheck.
    test: psql -U postgres -d chinook -c "select count(*) from \"Artist\""
```

Alternatively, add to the file from the command line.

```bash
cat <<'EOF' >> docker-compose.yaml
  postgres:
    image: postgres:16          # Use a modern version of PostgreSQL.
    environment:                # Set its superuser username and password.
      POSTGRES_PASSWORD: postgres
    volumes:                    # Initialize from the contents of the initialization directory.
      - ./initdb.d-postgres:/docker-entrypoint-initdb.d:ro
    healthcheck:                # Use a sensible healthcheck.
      test: psql -U postgres -d chinook -c "select count(*) from \"Artist\""
EOF
```

-   **What did this do?:** This step addes the `postgres` service. PostgreSQL is used *both* as a Hasura data source *and* as the Hasura metadata database. In a more realistic setting, typically these will be different databases. In a tutorial, keeping them in one database is simpler. The Hasura metadata database is largel of incidental importance for this tutorial, since its only role is as a channel for synchronizing metadata changes across a horizontally-scaled cluster of Hasura instances. With only one instance, that obviously is irrelevant for this tutorial. Nevertheless, the presence of a metadata database is a *requirement* for Hasura v2 even to start.


<a id="orgdae680e"></a>

## Step 7:  Test the PostgreSQL service.

Use Docker Compose to start the `postgres` service.

```bash
docker compose up -d postgres
```

Run a query against the database to verify that it has been initialized.

```bash
docker exec scratch-postgres-1 psql -U postgres -d chinook -c "select count(*) from \"Artist\""
```

-   **What did this do?:** This step launched the Docker Compose `postgres` service and ran a test query just to validate that it has been initialized properly.


<a id="orgc1653e0"></a>

## Step 8:  Create a MongoDB initialization directory.

Create a directory to mount into the MongoDB container in order to initialize the database.

```bash
mkdir -p initdb.d-mongo
```

-   **What did this do?:** This step creates a directory that will be mounted into the MongoDB container as a volume, in a special directory that the container image uses to access initialization files.


<a id="org5063eee"></a>

## Step 9:  Download the MongoDB initialization files.

Download Mongo DB initialization files into its initialization directory.

```bash
wget -O initdb.d-mongo/01_import_data.sh https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-mongo/01_import_data.sh
wget -O initdb.d-mongo/postgres.Album.json https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-mongo/postgres.Album.json
wget -O initdb.d-mongo/postgres.Artist.json https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-mongo/postgres.Artist.json
wget -O initdb.d-mongo/postgres.Track.json https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-mongo/postgres.Track.json
```

-   **What did this do?:** This step downloaded MongoDB initialization scripts and related data files from this GitHub repository.


<a id="org47d2a45"></a>

## Step 10:  Add the `mongo` service.

Use a code editor to add a stanza for the `mongo` service.

```yaml
mongo:
  image: mongo:6              # Use a modern version of MongoDB.
  environment:                # Set its superuser username and password.
    MONGO_INITDB_ROOT_PASSWORD: mongo
    MONGO_INITDB_ROOT_USERNAME: mongo
  volumes:                    # Initialize from the contents of the initialization directory.
    - ./initdb.d-mongo:/docker-entrypoint-initdb.d:ro
  depends_on:                 # Wait until postgres starts up first.
    postgres:
      condition: service_healthy
```

Alternatively, add to the file from the command line.

```bash
cat <<'EOF' >> docker-compose.yaml
  mongo:
    image: mongo:6              # Use a modern version of MongoDB.
    environment:                # Set its superuser username and password.
      MONGO_INITDB_ROOT_PASSWORD: mongo
      MONGO_INITDB_ROOT_USERNAME: mongo
    volumes:                    # Initialize from the contents of the initialization directory.
      - ./initdb.d-mongo:/docker-entrypoint-initdb.d:ro
    depends_on:                 # Wait until postgres starts up first.
      postgres:
        condition: service_healthy
EOF
```

-   **What did this do?:** This step added a stanza for the `mongo` service to the Docker Compose file.


<a id="org69a9b48"></a>

## Step 12:  Test the MongoDB service.

User Docker Compose to start the `mongo` service.

```bash
docker compose up -d mongo
```

Run a query against the database to verify that it has been initialized.

```bash
docker exec scratch-mongo-1 mongosh --quiet -u mongo -p mongo --eval "db.postgres.Album.findOne()" admin 
```

-   **What did this do?:** This step used the `mongosh` shell to execute a simple query against the `mongo` service, to check that it has been initialized properly.


<a id="org0c80fc5"></a>

## Step 13:  Add the `mongo_data_connector` service.

Use a code editor to add a stanza for the `mongo-data-connector` service.

```yaml
mongo_data_connector:         # Start the connector agent.
  image: hasura/mongo-data-connector:v2.38.0
  depends_on:                 # Wait until mongo starts up first.
    - mongo
```

Alternatively, add to the file from the command line.

```bash
cat <<'EOF' >> docker-compose.yaml
  mongo_data_connector:         # Start the connector agent.
    image: hasura/mongo-data-connector:v2.38.0
    depends_on:                 # Wait until mongo starts up first.
      - mongo
EOF
```

-   **What did this do?:** This step added a MongoDB connector service to the Docker Compose file. Hasura uses an independent connector agent for certain databases, such as MongoDB.


<a id="orgaefc138"></a>

## Step 14:  Add the `redis` service.

Use a code editor to add a stanza for the `redis` service.

```yaml
redis:
  image: redis:latest
```

Alternatively, add to the file from the command line.

```bash
cat <<'EOF' >> docker-compose.yaml
  redis:
    image: redis:latest
EOF
```

-   **What did this do?:** This step added a Redis service to the Docker Compose file. Hasura EE uses Redis in two ways. First, Redis is used for caching. Second, Redis is used to store counters and other data that are used by Hasura security features like rate-limiting.


<a id="org98e1036"></a>

## Step 15:  Add Hasura.

Use a code editor to add a stanza for the `hasura` service.

```yaml
hasura:                       # Start Hasura.
  image: hasura/graphql-engine:v2.40.0
  depends_on:                 # Wait until the connector agent starts up first.
    - mongo_data_connector
  ports:                      # Expose it on a port taken from an environment variable
    - ${HGPORT}:8080
  healthcheck:                # Use a sensible healthcheck.
    test: curl -s http://localhost:8080/healthz
    start_period: 60s
  environment:                # Configure Hasura.
    HASURA_GRAPHQL_ADMIN_SECRET: hasura # Hasura EE requires an admin secret.
    HASURA_GRAPHQL_DEV_MODE: true       # We require dev mode.
    HASURA_GRAPHQL_EE_LICENSE_KEY: ${HASURA_GRAPHQL_EE_LICENSE_KEY} # Hasura EE requires a license key.
    HASURA_GRAPHQL_ENABLE_CONSOLE: true # We require Hasura Console.
    HASURA_GRAPHQL_MAX_CACHE_SIZE: 200  # Set Redis cache size.
    HASURA_GRAPHQL_METADATA_DATABASE_URL: postgres://postgres:postgres@postgres/metadata # Hasura requires a PostgreSQL DB for metadata.
    HASURA_GRAPHQL_METADATA_DEFAULTS: '{"backend_configs":{"dataconnector":{"Mongo":{"uri":"http://mongo_data_connector:3000"}}}}' # Tell Hasura about the connector agent.
    HASURA_GRAPHQL_RATE_LIMIT_REDIS_URL: redis://redis:6379 # Set the Redis URL for rate-limiting.
    HASURA_GRAPHQL_REDIS_URL: redis://redis:6379            # Use the same Redis URL for caching.
```

Alternatively, add to the file from the command line.

```bash
cat <<'EOF' >> docker-compose.yaml
  hasura:                       # Start Hasura.
    image: hasura/graphql-engine:v2.40.0
    depends_on:                 # Wait until the connector agent starts up first.
      - mongo_data_connector
    ports:                      # Expose it on a port taken from an environment variable
      - ${HGPORT}:8080
    healthcheck:                # Use a sensible healthcheck.
      test: curl -s http://localhost:8080/healthz
      start_period: 60s
    environment:                # Configure Hasura.
      HASURA_GRAPHQL_ADMIN_SECRET: hasura # Hasura EE requires an admin secret.
      HASURA_GRAPHQL_DEV_MODE: true       # We require dev mode.
      HASURA_GRAPHQL_EE_LICENSE_KEY: ${HASURA_GRAPHQL_EE_LICENSE_KEY} # Hasura EE requires a license key.
      HASURA_GRAPHQL_ENABLE_CONSOLE: true # We require Hasura Console.
      HASURA_GRAPHQL_MAX_CACHE_SIZE: 200  # Set Redis cache size.
      HASURA_GRAPHQL_METADATA_DATABASE_URL: postgres://postgres:postgres@postgres/metadata # Hasura requires a PostgreSQL DB for metadata.
      HASURA_GRAPHQL_METADATA_DEFAULTS: '{"backend_configs":{"dataconnector":{"Mongo":{"uri":"http://mongo_data_connector:3000"}}}}' # Tell Hasura about the connector agent.
      HASURA_GRAPHQL_RATE_LIMIT_REDIS_URL: redis://redis:6379 # Set the Redis URL for rate-limiting.
      HASURA_GRAPHQL_REDIS_URL: redis://redis:6379            # Use the same Redis URL for caching.
EOF
```

-   **What did this do?:** This step added a service to the Docker Compose file for `hasura`.


<a id="orgcf4b6a0"></a>

## Step 16:  Set environment variables.

Set environment variables to be used by Docker Compose but which should not be hard-coded into the Docker Compose file

```bash
export HASURA_GRAPHQL_EE_LICENSE_KEY=<your EE license key>
export HGPORT=8081		# or your own port
```

-   **What did this do?:** This step set the two environment variables that are actually necessary.
    -   **`HASURA_GRAPHQL_EE_LICENSE_KEY`:** Because this tutorial uses Enterprise features like Redis caching and the MongoDB connector agent, we need to use the Hasura EE version with a valid license key.
    -   **`HGPORT`:** Because we need to use Hasura Console in Part B of this tutorial, we need to access both it and the `graphql-engine` instance within the container.


<a id="org17c83bb"></a>

## Step 17:  Start the `mongo_data_connector`, `redis` and `hasura` services.

Use Docker Compose to start the `mongo_data_connector`, `redis` and `hasura` services.

```bash
docker compose up -d mongo_data_connector redis hasura
```

-   **What did this do?:** This step


<a id="org901bd2e"></a>

## Step 18:  Open the Hasura Console and log in.

Open a browser to the Hasura Console.

```bash
xdg-open http://localhost:8081	# or your own port
```

-   **What did this do?:** This step just launched a web browser to the running instance of graphql-engine, which will cause the Hasura Console interface to appear.


<a id="org3d63861"></a>

# Part B:  In Hasura Console

<2024-07-31_10-53-36.mp4>

```bash
docker exec scratch-mongo-1 mongosh --quiet -u mongo -p mongo --eval "EJSON.stringify(db.postgres.Artist.findOne())" admin
```

<iframe width="560" height="315" src="https://www.youtube.com/embed/y5Gy__xLQhk?si=HJ0DcKbODc8Ed0g9" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
