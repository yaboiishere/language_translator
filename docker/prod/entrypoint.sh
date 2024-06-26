#!/bin/sh

. /app/.env
export NODE_ID="$(hostname -i)"
echo "Starting language_translator NODE_ID=${NODE_ID}"
echo """
#!/bin/sh
export RELEASE_NODE=language_translator@${NODE_ID}
export RELEASE_DISTRIBUTION=name
""" > /app/releases/0.1.0/env.sh

gcloud auth activate-service-account --key-file=service_account.json

# wait until Postgres is ready
while ! pg_isready -q -h $PGHOST -p $PGPORT -U $PGUSER
do
  echo "$(date) $PGHOST:$PGPORT - waiting for database to start"
  sleep 2
done

bin="/app/bin/language_translator"
eval "$bin eval \"LanguageTranslator.Release.create\""
set -e
eval "$bin eval \"LanguageTranslator.Release.migrate\""
exec "$bin" "start"

