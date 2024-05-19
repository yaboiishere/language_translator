#!/bin/sh

. /app/.env
export NODE_ID="$(hostname -i)"
echo "Starting language_translator NODE_ID=${NODE_ID}"
gcloud auth activate-service-account --key-file=service_account.json

# wait until Postgres is ready
while ! pg_isready -q -h $PGHOST -p $PGPORT -U $PGUSER
do
  echo "$(date) - waiting for database to start"
  sleep 2
done

bin="/app/bin/language_translator"
eval "$bin eval \"LanguageTranslator.Release.create\""
set -e
eval "$bin eval \"LanguageTranslator.Release.migrate\""
exec "$bin" "start"

