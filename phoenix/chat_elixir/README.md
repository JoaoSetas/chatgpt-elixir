# Installation with docker
## Clone the repo

```BASH
git clone https://github.com/JoaoSetas/chatgpt-elixir.git
```
## Configuring .env
Create the folder `.env` from the `.env.example`

Get the `SECRET_KEY_BASE` with
```BASH
docker-compose run phoenix_dev mix phx.gen.secret
```
## Starting containers
Start the containers
```BASH
docker-compose up -d
```
Now you should see the app in http://localhost:4000/
# Development Setup
Checks before commit
```BASH
docker-compose run --rm phoenix_dev sh run-checks.sh
```
Get logs
```BASH
docker-compose logs -f
```
Connect to the container
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
dbg(variable)
```
It needed in the iex this command recompiles any changes 
```elixir
recompile
```

# Test

Run tests
```BASH
docker-compose run phoenix_dev sh run-checks.sh
```
Debug tests (run inside a app in the container)
```BASH
docker-compose run --rm phoenix_dev bash -c "MIX_ENV=test iex -S mix test --trace"
```

# Production

Setup gigalixir with https://www.gigalixir.com/docs/getting-started-guide/

Push to production
```BASH
git push gigalixir
```

Verify if healthy
```BASH
gigalixir ps
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