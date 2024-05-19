#!/bin/sh

. /app/.env
export NODE_ID="${ENV}-$(hostname | rev | cut -d_ -f1 | rev)"
echo "Starting language_translator NODE_ID=${NODE_ID}"

# wait until Postgres is ready
while ! pg_isready -q -h $PGHOST -p $PGPORT -U $PGUSER
do
  echo "$(date) - waiting for database to start"
  sleep 2
done

gcloud auth activate-service-account --key-file=service_account.json


bin="/app/bin/language_translator"
eval "$bin eval \"LanguageTranslator.Release.migrate\""
exec "$bin" "start"

