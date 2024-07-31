- [What](#org8540d52)
- [Why](#org36b244e)
- [How](#org404c208)
- [Part A:  At the Command Line](#org389398d)
  - [Step 1:  Create a new directory.](#orgbd28195)
  - [Step 2:  Create a PostgreSQL initialization directory.](#org5f30d7d)
  - [Step 3:  Download the PostgreSQL initialization files.](#org5f63608)
  - [Step 4:  Scaffold the Docker Compose file.](#orgcb37960)
  - [Step 5:  Add the `postgres` service.](#org0c1a8ef)
  - [Step 7:  Test the PostgreSQL service.](#org987d0e4)
  - [Step 8:  Create a MongoDB initialization directory.](#org61645b4)
  - [Step 9:  Download the MongoDB initialization files.](#org0a40176)
  - [Step 10:  Add the `mongo` service.](#orgdcd2d67)
  - [Step 11:  Test the MongoDB service.](#org0af8e4b)
  - [Step 12:  Add the `mongo_data_connector` service.](#org7b29a71)
  - [Step 13:  Add the `redis` service.](#org63f5b86)
  - [Step 14:  Add Hasura.](#org4e9c2da)
  - [Step 15:  Set environment variables.](#org8347ee2)
  - [Step 16:  Start the `mongo_data_connector`, `redis` and `hasura` services.](#orgf81c6de)
  - [Step 17:  Open the Hasura Console and log in.](#orgb8da538)
- [Part B:  In Hasura Console](#org08c8d63)
  - [Step 1:  Add the postgres database and track its tables.](#org6ccb8d7)
  - [Step 2:  Add the mongo database and track the mongo collections](#org29a3019)
  - [Step 3:  Add relationships.](#orgc30fc66)
  - [Step 4:  Try a sample query.](#org187fb60)



<a id="org8540d52"></a>

# What

This project comprises instructions for setting up heterogeneous data sources with Hasura v2.


<a id="org36b244e"></a>

# Why

There can never be too many tutorials, walk-throughs, and lighted pathways for setting up Hasura. This is yet another one.


<a id="org404c208"></a>

# How

This project uses Docker Compose to launch services for PostgreSQL, for MongoDB, for Redis, for Hasura, and for a Hasura Data Connector. It also relies on a handful of environment variables to be supplied by the user. As a tutorial, it is divided into two parts: Part A and Part B.

Part A offers a sequence of steps to be performed at the Command Line and optionally in a text editor, to create a Docker Compose file and to acquire supporting initialization files to create the services.

Part B offers a sequence of steps to be performed in Hasura Console once all the services have been launched.


<a id="org389398d"></a>

# Part A:  At the Command Line


<a id="orgbd28195"></a>

## Step 1:  Create a new directory.

Create a directory to work in and move to it.

```bash
rm -rf scratch
mkdir -p scratch
cd scratch
```

-   **What did this do?:** This step just creates a scratch workspace for the project.


<a id="org5f30d7d"></a>

## Step 2:  Create a PostgreSQL initialization directory.

Create a directory to mount into the PostgreSQL container in order to initialize the database.

```bash
mkdir -p initdb.d-postgres
```

-   **What did this do?:** This step creates a directory that will be mounted into the PostgreSQL container as a volume, in a special directory that the container image uses to access initialization files.


<a id="org5f63608"></a>

## Step 3:  Download the PostgreSQL initialization files.

Download PostgreSQL initialization scripts into its initialization directory.

```bash
wget -O initdb.d-postgres/03_chinook_database.sql https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-postgres/03_chinook_database.sql
wget -O initdb.d-postgres/04_chinook_ddl.sql https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-postgres/04_chinook_ddl.sql
wget -O initdb.d-postgres/05_chinook_dml.sql https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-postgres/05_chinook_dml.sql
```

-   **What did this do?:** This step downloaded PostgreSQL SQL initialization files from this GitHub repository, with DDL and DML for the Chinook sample database.


<a id="orgcb37960"></a>

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


<a id="org0c1a8ef"></a>

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

-   **What did this do?:** This step adds the `postgres` service. PostgreSQL is used *both* as a Hasura data source *and* as the Hasura metadata database. In a more realistic setting, typically these will be different databases. In a tutorial, keeping them in one database is simpler. The Hasura metadata database is largely of incidental importance for this tutorial, since its only role is as a channel for synchronizing metadata changes across a horizontally-scaled cluster of Hasura instances. With only one instance, that obviously is irrelevant for this tutorial. Nevertheless, the presence of a metadata database is a *requirement* for Hasura v2 even to start.


<a id="org987d0e4"></a>

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


<a id="org61645b4"></a>

## Step 8:  Create a MongoDB initialization directory.

Create a directory to mount into the MongoDB container in order to initialize the database.

```bash
mkdir -p initdb.d-mongo
```

-   **What did this do?:** This step creates a directory that will be mounted into the MongoDB container as a volume, in a special directory that the container image uses to access initialization files.


<a id="org0a40176"></a>

## Step 9:  Download the MongoDB initialization files.

Download Mongo DB initialization files into its initialization directory.

```bash
wget -O initdb.d-mongo/01_import_data.sh https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-mongo/01_import_data.sh
wget -O initdb.d-mongo/postgres.Album.json https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-mongo/postgres.Album.json
wget -O initdb.d-mongo/postgres.Artist.json https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-mongo/postgres.Artist.json
wget -O initdb.d-mongo/postgres.Track.json https://raw.githubusercontent.com/hasura/hasura-v2-demo-heterogeneous/main/initdb.d-mongo/postgres.Track.json
```

-   **What did this do?:** This step downloaded MongoDB initialization scripts and related data files from this GitHub repository.


<a id="orgdcd2d67"></a>

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


<a id="org0af8e4b"></a>

## Step 11:  Test the MongoDB service.

User Docker Compose to start the `mongo` service.

```bash
docker compose up -d mongo
```

Run a query against the database to verify that it has been initialized.

```bash
docker exec scratch-mongo-1 mongosh --quiet -u mongo -p mongo --eval "db.postgres.Album.findOne()" admin
```

-   **What did this do?:** This step used the `mongosh` shell to execute a simple query against the `mongo` service, to check that it has been initialized properly.


<a id="org7b29a71"></a>

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


<a id="org63f5b86"></a>

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


<a id="org4e9c2da"></a>

## Step 14:  Add Hasura.

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


<a id="org8347ee2"></a>

## Step 15:  Set environment variables.

Set environment variables to be used by Docker Compose but which should not be hard-coded into the Docker Compose file

```bash
export HASURA_GRAPHQL_EE_LICENSE_KEY=<your EE license key>
export HGPORT=8081		# or your own port
```

-   **What did this do?:** This step set the two environment variables that are actually necessary.
    -   **`HASURA_GRAPHQL_EE_LICENSE_KEY`:** Because this tutorial uses Enterprise features like Redis caching and the MongoDB connector agent, we need to use the Hasura EE version with a valid license key.
    -   **`HGPORT`:** Because we need to use Hasura Console in Part B of this tutorial, we need to access both it and the `graphql-engine` instance within the container.


<a id="orgf81c6de"></a>

## Step 16:  Start the `mongo_data_connector`, `redis` and `hasura` services.

Use Docker Compose to start the `mongo_data_connector`, `redis` and `hasura` services.

```bash
docker compose up -d mongo_data_connector redis hasura
```

-   **What did this do?:** This step


<a id="orgb8da538"></a>

## Step 17:  Open the Hasura Console and log in.

Open a browser to the Hasura Console.

```bash
xdg-open http://localhost:8081	# or your own port
```

-   **What did this do?:** This step just launched a web browser to the running instance of graphql-engine, which will cause the Hasura Console interface to appear.


<a id="org08c8d63"></a>

# Part B:  In Hasura Console


<a id="org6ccb8d7"></a>

## Step 1:  Add the postgres database and track its tables.

Use Hasura Console as illustrated here to add the `postgres` database and track its tables.

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

[Step 1](https://github.com/user-attachments/assets/77424ec0-e1ed-4241-92e8-7ed3ea5ba261)

-   **What did this do?:** This step used Hasura Console to edit the Hasura metadata in order to add the `postgres` database (itself a Docker Compose service) as a data source. It also "tracked" these tables, which means to add them to the GraphQL API.


<a id="org29a3019"></a>

## Step 2:  Add the mongo database and track the mongo collections

Use Hasura Console as illustrated here to add the `mongo` database.

The database url is: `mongodb://mongo:mongo@mongo:27017`

The database is: `admin`

Use Hasura Console as illustrated here to track the `mongo` collections.

Note that because MongoDB is a document database and can hold data without a schema, an extra step is involved to choose the type for the GraphQL schema. A sample document from the MongoDB collection is taken and used to generate corresponding Hasura Logical Models. To do this, run these commands and copy the output into Hasura Console when track the collections.

```bash
docker exec scratch-mongo-1 mongosh --quiet -u mongo -p mongo --eval "EJSON.stringify(db.postgres.Artist.findOne())" admin
docker exec scratch-mongo-1 mongosh --quiet -u mongo -p mongo --eval "EJSON.stringify(db.postgres.Album.findOne())" admin
docker exec scratch-mongo-1 mongosh --quiet -u mongo -p mongo --eval "EJSON.stringify(db.postgres.Track.findOne())" admin
```

    {"_id":{"$oid":"6637f6ce7cda30b626bb1e62"},"ArtistId":1,"Name":"AC/DC"}
    {"_id":{"$oid":"6637f6cc7cda30b626bb1d07"},"AlbumId":1,"Title":"For Those About To Rock We Salute You","ArtistId":1}
    {"_id":{"$oid":"6637f6ce7cda30b626bb1f75"},"TrackId":1,"Name":"For Those About To Rock (We Salute You)","AlbumId":1,"MediaTypeId":1,"GenreId":1,"Composer":"Angus Young, Malcolm Young, Brian Johnson","Milliseconds":343719,"Bytes":11170334,"UnitPrice":0.99}

[Step 2](https://github.com/user-attachments/assets/9b2c7c46-d7e3-41ef-aa81-c39f77feaabc)

-   **What did this do?:** This step used Hasura Console to edit the Hasura metadata in order to add the `mongo` database (also a Docker Compose service) as a data source. As discussed above, it also sampled the mongo collections in order to track its collections with suitable Logical Models.


<a id="orgc30fc66"></a>

## Step 3:  Add relationships.

Use Hasura Console as illustrated here to add relationships between MongoDB collections and PostgreSQL tables.

[Step 3](https://github.com/user-attachments/assets/c514385b-5641-41d7-aa1f-080688657943)

-   **What did this do?:** This step used Hasura Console to edit the Hasura metadata in order to establish relationships between tracked MongoDB collections and tracked PostgreSQL tables. This is the crucial step that links data between different data sources.


<a id="org187fb60"></a>

## Step 4:  Try a sample query.

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
