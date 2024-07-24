#!/bin/sh

set -e

mongoimport -d admin --jsonArray --upsert -u mongo -p mongo /docker-entrypoint-initdb.d/postgres.Artist.json
mongoimport -d admin --jsonArray --upsert -u mongo -p mongo /docker-entrypoint-initdb.d/postgres.Album.json
mongoimport -d admin --jsonArray --upsert -u mongo -p mongo /docker-entrypoint-initdb.d/postgres.Track.json
