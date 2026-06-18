SHELL := /bin/sh

VERSION ?= $(shell git describe --tags --always 2>/dev/null || echo 0.0.0-unknown)
CACHE_DIR ?= .buildx-cache
CACHE_FROM ?= type=local,src=$(CACHE_DIR)
CACHE_TO ?= type=local,dest=$(CACHE_DIR),mode=max

DOCKER_BUILD := docker buildx build --load --build-arg APP_VERSION="$(VERSION)" --cache-from $(CACHE_FROM) --cache-to $(CACHE_TO)
DOCKER_COMPOSE := APP_VERSION="$(VERSION)" docker compose

BUILD_IMAGE := simdb-dashboard:build
SERVICE_IMAGE := simdb-dashboard:service

.DEFAULT_GOAL := service

.PHONY: \
	help \
	service \
	up \
	down \
	builder \
	lint \
	test \
	build \
	npm-dev \
	version \
	dist \
	update-base \
	update-deps \
	distclean \
	deploy

help:
	@echo "Core workflow:"
	@echo "  make service         Build lint stage, build stage, then tag final service image"
	@echo ""
	@echo "Compose service (make service first):"
	@echo "  make up              Start simdb-dashboard service using prebuilt service image"
	@echo "  make down            Stop simdb-dashboard service"
	@echo ""
	@echo "Dockerfile stage targets:"
	@echo "  make builder         Build builder stage (dependency setup + source prep)"
	@echo "  make lint            Build and run lint stage"
	@echo "  make test            Build and run Docker test stage"
	@echo "  make build           Build application build stage and tag $(BUILD_IMAGE)"
	@echo ""
	@echo "Developer utilities:"
	@echo "  make npm-dev         Run Vite dev server with bind mount for live local changes"
	@echo "  make version         Show git-derived application version"
	@echo ""
	@echo "Artifacts and maintenance:"
	@echo "  make dist            Save static app/dist artifact from $(BUILD_IMAGE) to ./dist"
	@echo "  make update-base     Rebuild service image pulling latest base images"
	@echo "  make update-deps     Update npm lockfile and audit-fix deps via Docker"
	@echo "  make distclean       Remove local artifacts and compose runtime state"
	@echo "  make deploy          Deploy project (placeholder)"
	@echo ""
	@echo "Environment variable examples:"
	@echo "  Start simdb-dashboard service on alternative port:"
	@echo "    DASHBOARD_PORT=18080 make up"
	@echo "  Build with local buildx cache:"
	@echo "    CACHE_FROM=type=local,src=.buildx-cache CACHE_TO=type=local,dest=.buildx-cache,mode=max make lint"
	@echo "  Build with GitHub Actions buildx cache:"
	@echo "    CACHE_FROM=type=gha,scope=simdb-dashboard CACHE_TO=type=gha,mode=max,scope=simdb-dashboard make lint"

# Compose targets
up:
	$(DOCKER_COMPOSE) up -d --no-build

down:
	$(DOCKER_COMPOSE) down

# Dockerfile stages
builder:
	$(DOCKER_BUILD) --target builder .

lint:
	$(DOCKER_BUILD) --target lint .

test:
	$(DOCKER_BUILD) --target test .

build:
	$(DOCKER_BUILD) --target build -t $(BUILD_IMAGE) .

service:
	$(DOCKER_BUILD) --target service -t $(SERVICE_IMAGE) .

# Developer utilities
npm-dev:
	docker run --rm -p 5173:5173 -v "$(PWD)/dashboard":/app -w /app node:24-alpine sh -c \
		"npm ci && npm run dev -- --host 0.0.0.0 --port 5173"

version:
	@echo $(VERSION)

# Artifacts and maintenance
dist: build
	mkdir -p dist
	docker rm -f tmp_dist_container >/dev/null 2>&1 || true
	docker create --name tmp_dist_container $(BUILD_IMAGE) >/dev/null
	docker cp tmp_dist_container:/app/dist ./dist
	docker rm tmp_dist_container >/dev/null

update-base:
	$(DOCKER_BUILD) --pull --target service -t $(SERVICE_IMAGE) .

update-deps: dashboard/package-lock.json

# File target: only runs if package-lock.json is missing or older than package.json.
dashboard/package-lock.json: dashboard/package.json
	docker run --rm -v "$(PWD)/dashboard":/app -w /app node:24-alpine sh -c \
		"npm install --package-lock-only && npm audit fix && npm list"

distclean:
	$(DOCKER_COMPOSE) down --volumes --remove-orphans --rmi local
	docker rmi -f $(BUILD_IMAGE) $(SERVICE_IMAGE) >/dev/null 2>&1 || true
	rm -rf dist

# Deployment
deploy:
	@echo "TODO define deploy workflow here"

