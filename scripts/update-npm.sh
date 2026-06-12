#!/bin/sh
# run from project root dir

# docker run --rm -v "$(pwd)/dashboard":/app -w /app node:24-alpine sh -c "npm install -g npm-check-updates && ncu -u && npm install --verbose && npm list"

docker run --rm -v "$(pwd)/dashboard":/app -w /app node:24-alpine sh -c "npm install --package-lock-only --verbose && npm audit fix --verbose && npm list"

