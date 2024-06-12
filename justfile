set dotenv-load

default:
  just start

start:
  iex -S mix phx.server

compose *args:
  docker-compose {{args}}

iex:
  docker-compose exec app iex -S mix

shell:
  docker-compose exec app /bin/bash

mix *args:
  mix {{args}}

dmix *args:
  docker-compose exec app mix {{args}}

test *args:
  mix test {{args}}

dockerize:
  docker build -t language_translator:latest .
  docker tag language_translator:latest ghcr.io/yaboiishere/language_translator:latest
  docker push ghcr.io/yaboiishere/language_translator:latest

swarm:
  export $(cat .env.prod) > /dev/null 2>&1; docker stack deploy -c docker-compose.yml --with-registry-auth language_translator

test_e2e *args:
  /usr/bin/java -jar /usr/share/selenium-server/selenium-server-standalone.jar &
  MIX_ENV=test mix test.e2e {{args}}
  bash -c 'kill -9 $(lsof -t -i:4444)'
  
