# Running

To start the service locally run `docker-compose up -d --build` and `docker-compose down` to stop everything

# Tests

Redis is required to be running for the tests. You can start one locally using `docker-compose up -d redis`. Then the tests and linter can be run using just `task`
