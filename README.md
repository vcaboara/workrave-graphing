# Workrave Stats Visualizer

This application parses Workrave statistics and generates dynamic graphs.

## Usage

1.  Run `docker-compose up --build`.
2.  Open your browser to `http://localhost:5000`.
3.  Upload your Workrave statistics CSV file.

## Development

* `docker-compose up --build`
* Run tests: `docker-compose exec web python -m pytest app/tests/`

## CI/CD

Jenkinsfile is set up for Docker Hub builds.

## Pre-commit hooks

```
pre-commit run --all-files # Run on all files
pre-commit run --files app/app.py # Run on a specific file
```
