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
