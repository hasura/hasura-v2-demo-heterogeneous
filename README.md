- [What](#orgb91743a)
- [Why](#org8cc1285)
- [How](#org849b4ab)
- [Part A:  At the Command Line](#org3542f12)
  - [Step 0:  (Optional) Skip directly to Part B > [Step 0](#orgad78b26).](#org60058f9)
  - [Step 1:  Create a new directory.](#org139b547)
  - [Step 2:  Create PostgreSQL initialization directories.](#orgdb015bf)
  - [Step 3:  Download the PostgreSQL initialization files.](#orgf9f98e4)
  - [Step 4:  Scaffold the Docker Compose file.](#orge82c9a7)
  - [Step 5:  Add the `postgres` service.](#org1fc122e)
  - [Step 6:  Add the `metadata` service.](#org751ff48)
  - [Step 7:  Test the `postgres` and `metadata` services.](#org2f8aa37)
  - [Step 8:  Create a MongoDB initialization directory.](#org91a20d7)
  - [Step 9:  Download the MongoDB initialization files.](#org30e1fe5)
  - [Step 10:  Add the `mongo` service.](#org753680b)
  - [Step 11:  Test the MongoDB service.](#org55fe25c)
  - [Step 12:  Add the `mongo_data_connector` service.](#org87b3fbb)
  - [Step 13:  Add the `redis` service.](#org18e2c43)
  - [Step 14:  Add a Hasura service for the `postgres` data source.](#orgd00c5d0)
  - [Step 15:  Add a Hasura service for the `mongo` data source.](#org4d0dca4)
  - [Step 16:  Add a Hasura service for the `gateway`.](#org4d07a6b)
  - [Step 17:  Set environment variables.](#orge7b493a)
  - [Step 18:  Start the remaining services.](#org7de95a3)
- [Part B:  In Hasura Console](#org0e785f1)
  - [Step 0:  (Optional) Start the services.](#orgad78b26)
  - [Step 1:  Open the Hasura Console and log in.](#orgcafcc77)
  - [Step 2:  Add the postgres database and track its tables and relationships.](#orgb1d4249)
  - [Step 3:  Add the mongo database and track its collections and relationships.](#org51b0f81)
  - [Step 4:  Add the Remote Schemas.](#org8627af4)
  - [Step 5:  Add Remote Relationships.](#org4d19091)
  - [Step 6:  Try a sample query.](#org4ea19a9)



<a id="orgb91743a"></a>

# What

This project comprises instructions for setting up heterogeneous data sources with Hasura v2.


<a id="org8cc1285"></a>

# Why

There can never be too many tutorials, walk-throughs, and lighted pathways for setting up Hasura. This is yet another one.


<a id="org849b4ab"></a>

# How

This project uses Docker Compose to launch services for PostgreSQL, for MongoDB, for Redis, for Hasura, and for a Hasura Data Connector. It also relies on a handful of environment variables to be supplied by the user. As a tutorial, it is divided into two parts: Part A and Part B.

Part A offers a sequence of steps to be performed at the Command Line and optionally in a text editor, to create a Docker Compose file and to acquire supporting initialization files to create the services.

Part B offers a sequence of steps to be performed in Hasura Console once all the services have been launched.


<a id="org3542f12"></a>

# Part A:  At the Command Line


<a id="org60058f9"></a>

## Step 0:  (Optional) Skip directly to Part B > [Step 0](#orgad78b26).

If you wish to avoid the lengthy and tedious sequence of steps in Part A, which build up the Docker Compose file and acquire initialization files, then skip directly to Part B and just use the Docker Compose file and initialization files that are already in this repository.


<a id="org139b547"></a>

## Step 1:  Create a new directory.

Create a directory to work in and move to it.

```bash
rm -rf scratch
mkdir -p scratch
cd scratch
```

-   **What did this do?:** This step just creates a scratch workspace for the project.


<a id="orgdb015bf"></a>

## Step 2:  Create PostgreSQL initialization directories.

Create directories to mount into the PostgreSQL containers in order to initialize their databases.

```bash
mkdir -p initdb.d-postgres
mkdir -p initdb.d-metadata
```

-   **What did this do?:** This step creates two directories that will be mounted into the PostgreSQL containers as volumes, in a special directory that the container image uses to access initialization files. There are two directories because there will be two PostgreSQL database services, `postgres` and `metadata`.


<a id="orgf9f98e4"></a>

## Step 3:  Download the PostgreSQL initialization files.

Download PostgreSQL initialization scripts into its initialization directory.

-   **[`02_chinook_database.sql`](https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/from-scratch/initdb.d-postgres/03_chinook_database.sql):** create the Chinook database
-   **[`04_chinook_ddl.sql`](https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/from-scratch/initdb.d-postgres/03_chinook_database.sql):** Chinook DDL (i.e. the tables)
-   **[`05_chinook_dml.sql`](https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/from-scratch/initdb.d-postgres/05_chinook_dml.sql):** Chinook DML (i.e. the data)

```bash
wget -O initdb.d-postgres/03_chinook_database.sql https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/from-scratch/initdb.d-postgres/03_chinook_database.sql
wget -O initdb.d-postgres/04_chinook_ddl.sql https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/from-scratch/initdb.d-postgres/04_chinook_ddl.sql
wget -O initdb.d-postgres/05_chinook_dml.sql https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/from-scratch/initdb.d-postgres/05_chinook_dml.sql
wget -O initdb.d-metadata/01_metadata_ddl.sql https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/from-scratch/initdb.d-postgres/03_chinook_database.sql
```

-   **What did this do?:** This step downloaded PostgreSQL SQL initialization files from this GitHub repository, with DDL and DML for the Chinook sample database and for the metadata database.


<a id="orge82c9a7"></a>

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


<a id="org1fc122e"></a>

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

-   **What did this do?:** This step adds the `postgres` service. PostgreSQL is used here as a Hasura data source but *not* as the Hasura metadata database. The same PosgreSQL database *can* be used as both a data source and as the Hasura metadata database. However, that is not a very practical approach. In a more realistic setting, typically these will be different databases. In a tutorial, keeping them in one database is often simpler. However, this tutorial *does* use separate databases (see the next step) to showcase a more realistic application. In any case, the Hasura metadata database is largely of incidental importance for this tutorial, since its only role is as a channel for synchronizing metadata changes across a horizontally-scaled cluster of Hasura instances. With only one instance, that obviously is irrelevant for this tutorial. Nevertheless, the presence of a metadata database is a *requirement* for Hasura v2 even to start.


<a id="org751ff48"></a>

## Step 6:  Add the `metadata` service.

Use a code editor to add a stanza for the `metadata` service.

```yaml
metadata:
  image: postgres:16          # Use a modern version of PostgreSQL.
  environment:                # Set its superuser username and password.
    POSTGRES_PASSWORD: postgres
  volumes:                    # Initialize from the contents of the initialization directory.
    - ./initdb.d-metadata:/docker-entrypoint-initdb.d:ro
```

Alternatively, add to the file from the command line.

```bash
cat <<'EOF' >> docker-compose.yaml
  metadata:
    image: postgres:16          # Use a modern version of PostgreSQL.
    environment:                # Set its superuser username and password.
      POSTGRES_PASSWORD: postgres
    volumes:                    # Initialize from the contents of the initialization directory.
      - ./initdb.d-metadata:/docker-entrypoint-initdb.d:ro
EOF
```

-   **What did this do?:** This step adds the `metadata` service. As discussed in the previous step, while the same PostgreSQL database *can* be used both as a data source and as its metadata database, this is not common in realistic applications. This tutorial endeavors to showcase a more realistic application, and so this step exists to set up a dedicated PostgreSQL metadata database.


<a id="org2f8aa37"></a>

## Step 7:  Test the `postgres` and `metadata` services.

Use Docker Compose to start the `postgres` and `metadata` services.

```bash
docker compose up -d postgres metadata
```

Run a query against the database to verify that it has been initialized.

```bash
docker exec scratch-postgres-1 psql -U postgres -d chinook -c "select count(*) from \"Artist\""
docker exec scratch-metadata-1 psql -U postgres -d metadata_1 -c "select 1"
docker exec scratch-metadata-1 psql -U postgres -d metadata_2 -c "select 2"
docker exec scratch-metadata-1 psql -U postgres -d metadata_3 -c "select 3"
```

-   **What did this do?:** This step launched the Docker Compose `postgres` service and ran a test query just to validate that it has been initialized properly.


<a id="org91a20d7"></a>

## Step 8:  Create a MongoDB initialization directory.

Create a directory to mount into the MongoDB container in order to initialize the database.

```bash
mkdir -p initdb.d-mongo
```

-   **What did this do?:** This step creates a directory that will be mounted into the MongoDB container as a volume, in a special directory that the container image uses to access initialization files.


<a id="org30e1fe5"></a>

## Step 9:  Download the MongoDB initialization files.

Download Mongo DB initialization files into its initialization directory.

-   **[`01_import_data.sh`](https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-mongo/01_import_data.sh):** main script
-   **[`postgres.Album.json`](https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-mongo/postgres.Album.json):** Album data
-   **[`postgres.Artist.json`](https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-mongo/postgres.Artist.json):** Artist data
-   **[`postgres.Track.json`](https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-mongo/postgres.Track.json):** Track data

```bash
wget -O initdb.d-mongo/01_import_data.sh https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-mongo/01_import_data.sh
wget -O initdb.d-mongo/postgres.Album.json https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-mongo/postgres.Album.json
wget -O initdb.d-mongo/postgres.Artist.json https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-mongo/postgres.Artist.json
wget -O initdb.d-mongo/postgres.Track.json https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-mongo/postgres.Track.json
```

-   **What did this do?:** This step downloaded MongoDB initialization scripts and related data files from this GitHub repository.


<a id="org753680b"></a>

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
EOF
```

-   **What did this do?:** This step added a stanza for the `mongo` service to the Docker Compose file.


<a id="org55fe25c"></a>

## Step 11:  Test the MongoDB service.

User Docker Compose to start the `mongo` service.

```bash
docker compose up -d mongo
```

Run a query against the database to verify that it has been initialized.

```bash
docker exec scratch-mongo-1 mongosh --quiet -u mongo -p mongo --eval "db.postgres.Artist.findOne()" admin
```

-   **What did this do?:** This step used the `mongosh` shell to execute a simple query against the `mongo` service, to check that it has been initialized properly.


<a id="org87b3fbb"></a>

## Step 12:  Add the `mongo_data_connector` service.

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


<a id="org18e2c43"></a>

## Step 13:  Add the `redis` service.

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


<a id="orgd00c5d0"></a>

## Step 14:  Add a Hasura service for the `postgres` data source.

Use a code editor to add a stanza for the `hasura1` service, which will access data from the `postgres` service.

```yaml
hasura1:                       # Start Hasura.
  image: hasura/graphql-engine:v2.40.0
  depends_on:                 # Wait until postgres starts up first.
    postgres:
      condition: service_healthy
  ports:                      # Expose it on a port taken from an environment variable
    - ${HGPORT1}:8080
  healthcheck:                # Use a sensible healthcheck.
    test: curl -s http://localhost:8080/healthz
    start_period: 60s
  environment:                # Configure Hasura.
    HASURA_GRAPHQL_ADMIN_SECRET: hasura # Hasura EE requires an admin secret.
    HASURA_GRAPHQL_DEV_MODE: true       # We require dev mode.
    HASURA_GRAPHQL_ENABLE_CONSOLE: true # We require Hasura Console.
    HASURA_GRAPHQL_METADATA_DATABASE_URL: postgres://postgres:postgres@metadata/metadata_1 # Hasura requires a PostgreSQL DB for metadata.
```

Alternatively, add to the file from the command line.

```bash
cat <<'EOF' >> docker-compose.yaml
  hasura1:                       # Start Hasura.
    image: hasura/graphql-engine:v2.40.0
    ports:                      # Expose it on a port taken from an environment variable
      - ${HGPORT1}:8080
    healthcheck:                # Use a sensible healthcheck.
      test: curl -s http://localhost:8080/healthz
      start_period: 60s
    environment:                # Configure Hasura.
      HASURA_GRAPHQL_ADMIN_SECRET: hasura # Hasura EE requires an admin secret.
      HASURA_GRAPHQL_DEV_MODE: true       # We require dev mode.
      HASURA_GRAPHQL_ENABLE_CONSOLE: true # We require Hasura Console.
      HASURA_GRAPHQL_METADATA_DATABASE_URL: postgres://postgres:postgres@metadata/metadata_1 # Hasura requires a PostgreSQL DB for metadata.
EOF
```

-   **What did this do?:** This step added a service to the Docker Compose file for `hasura1`.


<a id="org4d0dca4"></a>

## Step 15:  Add a Hasura service for the `mongo` data source.

Use a code editor to add a stanza for the `hasura2` service, which will access data from the `mongo` service.

```yaml
hasura2:                       # Start Hasura.
  image: hasura/graphql-engine:v2.40.0
  depends_on:                 # Wait until postgres starts up first.
    postgres:
      condition: service_started
  ports:                      # Expose it on a port taken from an environment variable
    - ${HGPORT2}:8080
  healthcheck:                # Use a sensible healthcheck.
    test: curl -s http://localhost:8080/healthz
    start_period: 60s
  environment:                # Configure Hasura.
    HASURA_GRAPHQL_ADMIN_SECRET: hasura # Hasura EE requires an admin secret.
    HASURA_GRAPHQL_DEV_MODE: true       # We require dev mode.
    HASURA_GRAPHQL_EE_LICENSE_KEY: ${HASURA_GRAPHQL_EE_LICENSE_KEY} # Hasura EE requires a license key.
    HASURA_GRAPHQL_ENABLE_CONSOLE: true # We require Hasura Console.
    HASURA_GRAPHQL_METADATA_DATABASE_URL: postgres://postgres:postgres@metadata/metadata_2 # Hasura requires a PostgreSQL DB for metadata.
    HASURA_GRAPHQL_METADATA_DEFAULTS: '{"backend_configs":{"dataconnector":{"Mongo":{"uri":"http://mongo_data_connector:3000"}}}}' # Tell Hasura about the connector agent.
```

Alternatively, add to the file from the command line.

```bash
cat <<'EOF' >> docker-compose.yaml
  hasura2:                       # Start Hasura.
    image: hasura/graphql-engine:v2.40.0
    depends_on:                 # Wait until postgres starts up first.
      metadata:
        condition: service_started
    ports:                      # Expose it on a port taken from an environment variable
      - ${HGPORT2}:8080
    healthcheck:                # Use a sensible healthcheck.
      test: curl -s http://localhost:8080/healthz
      start_period: 60s
    environment:                # Configure Hasura.
      HASURA_GRAPHQL_ADMIN_SECRET: hasura # Hasura EE requires an admin secret.
      HASURA_GRAPHQL_DEV_MODE: true       # We require dev mode.
      HASURA_GRAPHQL_EE_LICENSE_KEY: ${HASURA_GRAPHQL_EE_LICENSE_KEY} # Hasura EE requires a license key.
      HASURA_GRAPHQL_ENABLE_CONSOLE: true # We require Hasura Console.
      HASURA_GRAPHQL_METADATA_DATABASE_URL: postgres://postgres:postgres@metadata/metadata_2 # Hasura requires a PostgreSQL DB for metadata.
      HASURA_GRAPHQL_METADATA_DEFAULTS: '{"backend_configs":{"dataconnector":{"Mongo":{"uri":"http://mongo_data_connector:3000"}}}}' # Tell Hasura about the connector agent.
EOF
```

-   **What did this do?:** This step added a service to the Docker Compose file for `hasura2`. Note that because Hasura uses a Connector Agent for certain data sources, MongoDB being one of them, this Hasura instance has extra configuration information in the `environment` section specifying Mongo connector to be used. Note also that because MongoDB access is an enterprise feature, this instance is also configured with an EE license key.


<a id="org4d07a6b"></a>

## Step 16:  Add a Hasura service for the `gateway`.

Use a code editor to add a stanza for the `hasura3` service, which will act as a super-graph gateway to the other two Hasura services, `hasura1` and `hasura2`.

```yaml
hasura3:                       # Start Hasura.
  image: hasura/graphql-engine:v2.40.0
  ports:                      # Expose it on a port taken from an environment variable
    - ${HGPORT3}:8080
  depends_on:
    hasura1:
      condition: service_healthy
    hasura2:
      condition: service_healthy
  environment:                # Configure Hasura.
    HASURA_GRAPHQL_ADMIN_SECRET: hasura # Hasura EE requires an admin secret.
    HASURA_GRAPHQL_DEV_MODE: true       # We require dev mode.
    HASURA_GRAPHQL_EE_LICENSE_KEY: ${HASURA_GRAPHQL_EE_LICENSE_KEY} # Hasura EE requires a license key.
    HASURA_GRAPHQL_ENABLE_CONSOLE: true # We require Hasura Console.
    HASURA_GRAPHQL_MAX_CACHE_SIZE: 200  # Set Redis cache size.
    HASURA_GRAPHQL_METADATA_DATABASE_URL: postgres://postgres:postgres@metadata/metadata_3 # Hasura requires a PostgreSQL DB for metadata.
    HASURA_GRAPHQL_RATE_LIMIT_REDIS_URL: redis://redis:6379 # Set the Redis URL for rate-limiting.
    HASURA_GRAPHQL_REDIS_URL: redis://redis:6379            # Use the same Redis URL for caching.
```

Alternatively, add to the file from the command line.

```bash
cat <<'EOF' >> docker-compose.yaml
  hasura3:                       # Start Hasura.
    image: hasura/graphql-engine:v2.40.0
    ports:                      # Expose it on a port taken from an environment variable
      - ${HGPORT3}:8080
    depends_on:
      hasura1:
        condition: service_healthy
      hasura2:
        condition: service_healthy
    environment:                # Configure Hasura.
      HASURA_GRAPHQL_ADMIN_SECRET: hasura # Hasura EE requires an admin secret.
      HASURA_GRAPHQL_DEV_MODE: true       # We require dev mode.
      HASURA_GRAPHQL_EE_LICENSE_KEY: ${HASURA_GRAPHQL_EE_LICENSE_KEY} # Hasura EE requires a license key.
      HASURA_GRAPHQL_ENABLE_CONSOLE: true # We require Hasura Console.
      HASURA_GRAPHQL_MAX_CACHE_SIZE: 200  # Set Redis cache size.
      HASURA_GRAPHQL_METADATA_DATABASE_URL: postgres://postgres:postgres@metadata/metadata_3 # Hasura requires a PostgreSQL DB for metadata.
      HASURA_GRAPHQL_RATE_LIMIT_REDIS_URL: redis://redis:6379 # Set the Redis URL for rate-limiting.
      HASURA_GRAPHQL_REDIS_URL: redis://redis:6379            # Use the same Redis URL for caching.
EOF
```

-   **What did this do?:** This step added a service to the Docker Compose file for `hasura2`. Note that because Hasura uses a Connector Agent for certain data sources, MongoDB being one of them, this Hasura instance has extra configuration information in the `environment` section specifying Mongo connector to be used. Note also that because MongoDB access is an enterprise feature, this instance is also configured with an EE license key.


<a id="orge7b493a"></a>

## Step 17:  Set environment variables.

Set environment variables to be used by Docker Compose but which should not be hard-coded into the Docker Compose file

```bash
export HASURA_GRAPHQL_EE_LICENSE_KEY=<your EE license key>
export HGPORT1=8081		# or your own port
export HGPORT2=8082		# or your own port
export HGPORT3=8083		# or your own port
```

-   **What did this do?:** This step set the two environment variables that are actually necessary.
    -   **`HASURA_GRAPHQL_EE_LICENSE_KEY`:** Because this tutorial uses Enterprise features like Redis caching and the MongoDB connector agent, we need to use the Hasura EE version with a valid license key.
    -   **`HGPORT`:** Because we need to use Hasura Console in Part B of this tutorial, we need to access both it and the `graphql-engine` instance within the container.


<a id="org7de95a3"></a>

## Step 18:  Start the remaining services.

Use Docker Compose to start the `mongo_data_connector`, `redis`, `hasura_1`, `hasura_2`, and `hasura_3` services.

```bash
docker compose up -d mongo_data_connector redis hasura1 hasura2 hasura3
```

-   **What did this do?:** This step started the remaining services, which comprise the `mongo_data_connector` Connector Agent to mediate access to MongoDB, `redis` which will support caching and security features, and `hasura1`, `hasura2`, and `hasura3` which act as two sub-graphs for PostgreSQL and MongoDb and a super-graph gateway.


<a id="org0e785f1"></a>

# Part B:  In Hasura Console


<a id="orgad78b26"></a>

## Step 0:  (Optional) Start the services.

Use Docker Compose to ensure that all of the services are started. If they have already been started, then this step is a no-op. Do make sure that the necessary environment variables have been established first, however.

```bash
export HASURA_GRAPHQL_EE_LICENSE_KEY=<your EE license key>
export HGPORT1=8081		# or your own port
export HGPORT2=8082		# or your own port
export HGPORT3=8083		# or your own port
```

```bash
docker compose up -d
```


<a id="orgcafcc77"></a>

## Step 1:  Open the Hasura Console and log in.

Open a browser to the Hasura Console instances for all three Hasura instances.

```bash
xdg-open http://localhost:8081 &	# or your own port
xdg-open http://localhost:8082 &	# or your own port
xdg-open http://localhost:8083 &	# or your own port
```

-   **What did this do?:** This step just launched a web browser to the running instance of hasura1, which will cause the Hasura Console interface to appear.


<a id="orgb1d4249"></a>

## Step 2:  Add the postgres database and track its tables and relationships.

Use Hasura Console at <http://localhost:8081> (or your own port) as illustrated here to add the `postgres` database and track its tables and relationships.

The database url is: `postgres://postgres:postgres@postgres/chinook`.

Use Hasura Console as illustrated here to track *some* of the `postgres` tables:

-   Genre
-   MediaType
-   Playlist
-   PlaylistTrack
-   Customer
-   Invoice
-   InvoiceLine

Do not track these tables:

-   Artist
-   Album
-   Track

The reason not to track these tables in the `postgres` database is that these data will instead be brought in from the `mongo` database.

After tracking the tables listed above, Hasura Console will suggest relationships to track, which it infers from foreign-key constraints discovered while introspecting the database. These are only suggestions, and you are free to create whatever relations you like. Of course, those relationships should make sense and be semantically-valid within your data model. In this demo, it is sufficient just to choose the "Track All" option.

[2024-08-07_11-11-55.webm](https://github.com/user-attachments/assets/e7bdab84-313e-4210-a4a6-c8ab2727f92c)

-   **What did this do?:** This step used Hasura Console to edit the Hasura metadata in order to add the `postgres` database (itself a Docker Compose service) as a data source. It also "tracked" these tables, which means to add them to the GraphQL API.


<a id="org51b0f81"></a>

## Step 3:  Add the mongo database and track its collections and relationships.

Use Hasura Console at <http://localhost:8082> (or your own port) as illustrated here to add the `mongo` database.

The database url is: `mongodb://mongo:mongo@mongo:27017`

The database is: `admin`

Use Hasura Console as illustrated here to track the `mongo` collections.

**Note** that because MongoDB is a document database and can hold data without a schema, an extra step is involved to choose the type for the GraphQL schema. A sample document from the MongoDB collection is taken and used to generate corresponding Hasura Logical Models. To do this, run these commands and copy the output into Hasura Console when track the collections.

**Note** that it is important when tracking the collections in MongoDB to choose "Advanced Configuration" and then create a "Custom Collection Name" for each tracked collection:

-   **postgres.Artist:** track as `Artist`
-   **postgres.Album:** track as `Album`
-   **postgres.Track:** track as `Track`

```js
{"_id":{"$oid":"6637f6ce7cda30b626bb1e62"},"ArtistId":1,"Name":"AC/DC"}
```

```js
{"_id":{"$oid":"6637f6cc7cda30b626bb1d07"},"AlbumId":1,"Title":"For Those About To Rock We Salute You","ArtistId":1}
```

```js
{"_id":{"$oid":"6637f6ce7cda30b626bb1f75"},"TrackId":1,"Name":"For Those About To Rock (We Salute You)","AlbumId":1,"MediaTypeId":1,"GenreId":1,"Composer":"Angus Young, Malcolm Young, Brian Johnson","Milliseconds":343719,"Bytes":11170334,"UnitPrice":0.99}
```

```bash
docker exec scratch-mongo-1 mongosh --quiet -u mongo -p mongo --eval "EJSON.stringify(db.postgres.Artist.findOne())" admin
docker exec scratch-mongo-1 mongosh --quiet -u mongo -p mongo --eval "EJSON.stringify(db.postgres.Album.findOne())" admin
docker exec scratch-mongo-1 mongosh --quiet -u mongo -p mongo --eval "EJSON.stringify(db.postgres.Track.findOne())" admin
```

    {"_id":{"$oid":"6637f6ce7cda30b626bb1e62"},"ArtistId":1,"Name":"AC/DC"}
    {"_id":{"$oid":"6637f6cc7cda30b626bb1d07"},"AlbumId":1,"Title":"For Those About To Rock We Salute You","ArtistId":1}
    {"_id":{"$oid":"6637f6ce7cda30b626bb1f75"},"TrackId":1,"Name":"For Those About To Rock (We Salute You)","AlbumId":1,"MediaTypeId":1,"GenreId":1,"Composer":"Angus Young, Malcolm Young, Brian Johnson","Milliseconds":343719,"Bytes":11170334,"UnitPrice":0.99}

[2024-08-07_11-14-17.webm](https://github.com/user-attachments/assets/f905c2f9-5256-4f79-bc88-d25b0fc8acbb)

-   **What did this do?:** This step used Hasura Console to edit the Hasura metadata in order to add the `mongo` database (also a Docker Compose service) as a data source. As discussed above, it also sampled the mongo collections in order to track its collections with suitable Logical Models. Finally, it set up relationships between the Logical Models for this data source.


<a id="org8627af4"></a>

## Step 4:  Add the Remote Schemas.

Use Hasura Console at <http://localhost:8083> (or your own port) as illustrated here to add Remote Schemas to the other two Hasura instances.

The *internal* Docker endpoint for `hasura1` (PostgreSQL) is: `http://hasura1:8080/v1/graphql`.

The *internal* Docker endpoint for `hasura2` (MongoDB) is: `http://hasura2:8080/v1/graphql`.

Step 3

-   **What did this do?:** This step used Hasura Console to edit the Hasura metadata in order to add the two other Hasura sub-graph instances `hasura1` (PostgreSQL) and `hasura2` (MongoDB) as Remote Schemas. This establishes this third Hasura instance as a super-graph gateway.


<a id="org4d19091"></a>

## Step 5:  Add Remote Relationships.

Use Hasura Console at <http://localhost:8003> (or your own port) as illustrated here to add Remote Relationships between `hasura1` (PostgreSQL) and `hasura2` (MongoDB) collections.

[Step 3](https://github.com/user-attachments/assets/c514385b-5641-41d7-aa1f-080688657943)

-   **What did this do?:** This step used Hasura Console to edit the Hasura metadata in order to establish Remote Relationships between tracked MongoDB collections and tracked PostgreSQL tables in the two sub-graph Hasura instances. This is the crucial step that links data between different data sources.


<a id="org4ea19a9"></a>

## Step 6:  Try a sample query.

Use Hasura Console as illustrated here to try a sample GraphQL query that traverses both data source, `postgres` and `mongo`, via the relationships that were established earlier.

```graphql
query MyQuery {
  Artist(limit: 1) {
    Name
    albums(limit: 1) {
      Title
      tracks(limit: 1) {
        Name
        genre {
          Name
        }
        mediatype {
          Name
        }
        playlisttracks {
          PlaylistId
          Playlist {
            Name
          }
        }
      }
    }
  }
}
```

[Step 4](https://github.com/user-attachments/assets/fcb542bf-1338-49a0-b6c2-41f7674d458b)

-   **What did this do?:** This used the API tab in Hasura Console, itself a GraphQL client, to access the GraphQL endpoint, and issue a sample query.
