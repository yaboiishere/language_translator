default:
  docker-compose up -d

iex:
  docker-compose exec app iex -S mix

shell:
  docker-compose exec app /bin/bash

mix *args:
  docker-compose exec app mix {{args}}
