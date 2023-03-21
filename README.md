**[SearchSystem Documentation](https://bsolusdev.atlassian.net/wiki/spaces/SearchSystem/overview?homepageId=108822883) 🗎**
# Installation with docker
## Clone the repo

```BASH
git clone https://github.com/JoaoSetas/chatgpt-elixir.git
```
## Configuring .env
Create the folder `.env` from the example

Run this command generate a password and replace the `POSTGRES_PASSWORD` 
```BASH
openssl rand -hex 16
```
Get the `SECRET_KEY_BASE` with
```BASH
docker-compose run phoenix_dev mix phx.gen.secret
```
## Starting containers
Start the containers
```BASH
docker-compose --profile dev up -d
```
Now you should see the homepage in http://localhost:4000/
# Development Setup
Get logs
```BASH
docker-compose logs -f
```
Connect to elixir container
```BASH
docker-compose exec phoenix_dev bash
```
# Debug

Connect to the iex with 
```BASH
docker-compose exec phoenix_dev iex --sname console --cookie monster --remsh cookie
```
To debug in the iex put this in your code to break 
```elixir
require IEx; IEx.pry
```
It needed in the iex this command recompiles any changes 
```elixir
IEx.Helpers.recompile
```

# Test

Run tests
```BASH
docker-compose -f docker-compose.phoenix.yml run phoenix_dev sh run-checks.sh
```
Debug tests (run inside a app in the container)
```BASH
MIX_ENV=test iex -S mix test --trace
```

# Production

Commands available in the `umbrella_prod` container are in `bin/{{MAIN_APP}}_umbrella`

Start the containers
```BASH
docker-compose --profile prod -f docker-compose.elastic.yml -f docker-compose.phoenix.yml up -d
```

Create the prod db and run migrations manually by
```BASH
docker-compose -f docker-compose.phoenix.yml run umbrella_prod bin/{{MAIN_APP}}_umbrella eval "SearchSystem.Release.create"
```
or
```BASH
docker-compose -f docker-compose.phoenix.yml run umbrella_prod bin/{{MAIN_APP}}_umbrella eval "SearchSystem.Release.migrate"
```

Connect to the elixir shell by
```BASH
docker-compose -f docker-compose.phoenix.yml exec umbrella_prod bin/{{MAIN_APP}}_umbrella remote
```

# Stress test

`docker run -i --rm loadimpact/k6 run --vus 100 --duration 30s - <stress_test.js`

```javascript
    //script.js
    import http from 'k6/http';
    import { Trend } from 'k6/metrics';
    import { sleep } from 'k6';

    let myTrend = new Trend('waiting_time');

    export default function () {
        let r = http.get('http://host.docker.internal:4000/');

        myTrend.add(r.timings.waiting);

        sleep(1);
    }
```