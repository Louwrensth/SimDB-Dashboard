SHELL := /bin/sh

VERSION ?= $(shell git describe --tags --always 2>/dev/null || echo 0.0.0-unknown)

DOCKER_CMD ?= docker
DOCKER_BUILD ?= $(DOCKER_CMD) build --build-arg APP_VERSION="$(VERSION)"
DOCKER_COMPOSE ?= APP_VERSION="$(VERSION)" $(DOCKER_CMD) compose

BUILD_IMAGE := simdb-dashboard:build
DEV_IMAGE := simdb-dashboard:dev
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
	dev \
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
	@echo "  make logs-f          Follow logs of the started simdb-dashboard service"
	@echo "  make shell           Enter shell in the started simdb-dashboard service"
	@echo ""
	@echo "Dockerfile stage targets:"
	@echo "  make builder         Build builder stage (dependency setup + source prep)"
	@echo "  make build           Build application build stage and tag $(BUILD_IMAGE)"
	@echo ""
	@echo "Developer utilities:"
	@echo "  make lint            Runs npm run lint"
	@echo "  make type-check      Runs npm run type-check"
	@echo "  make test            Runs npm run test..."
	@echo "  make dev             Run Vite dev server from Docker dev stage with live local changes"
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

# Compose targets
up:
	$(DOCKER_COMPOSE) up -d --no-build

down:
	$(DOCKER_COMPOSE) down

logs-f:
	$(DOCKER_COMPOSE) logs -f

shell:
	$(DOCKER_COMPOSE) exec dashboard sh


# Dockerfile stages
builder:
	$(DOCKER_BUILD) --target builder .

build:
	$(DOCKER_BUILD) --target build -t $(BUILD_IMAGE) .

service:
	$(DOCKER_BUILD) --target service -t $(SERVICE_IMAGE) .

# Developer utilities
lint:
	$(DOCKER_CMD) run $(BUILD_IMAGE) npm run lint

type-check:
	$(DOCKER_CMD) run $(BUILD_IMAGE) npm run type-check

test:
	$(DOCKER_CMD) run $(BUILD_IMAGE) npm run test:unit -- --run

dev:
	$(DOCKER_BUILD) --target dev -t $(DEV_IMAGE) .
	$(DOCKER_CMD) run --rm -p 5173:5173 \
		-v "$(PWD)/dashboard":/app \
		-v simdb_dashboard_node_modules:/app/node_modules \
		-w /app $(DEV_IMAGE)

version:
	@echo $(VERSION)

# Artifacts and maintenance
dist: build
	mkdir -p dist
	$(DOCKER_CMD) rm -f tmp_dist_container >/dev/null 2>&1 || true
	$(DOCKER_CMD) create --name tmp_dist_container $(BUILD_IMAGE) >/dev/null
	$(DOCKER_CMD) cp tmp_dist_container:/app/dist/. ./dist
	$(DOCKER_CMD) rm tmp_dist_container >/dev/null

update-base:
	$(DOCKER_BUILD) --pull --target service -t $(SERVICE_IMAGE) .

update-deps: dashboard/package-lock.json

# File target: only runs if package-lock.json is missing or older than package.json.
dashboard/package-lock.json: dashboard/package.json
	$(DOCKER_CMD) run --rm -v "$(PWD)/dashboard":/app -w /app node:24-alpine sh -c \
		"npm install --package-lock-only && npm audit fix && npm list"

distclean:
	$(DOCKER_COMPOSE) down --volumes --remove-orphans --rmi local
	$(DOCKER_CMD) rmi -f $(BUILD_IMAGE) $(SERVICE_IMAGE) >/dev/null 2>&1 || true
	$(DOCKER_CMD) volume rm -f simdb_dashboard_node_modules >/dev/null 2>&1 || true
	rm -rf dist

# Deployment
deploy:
	@echo "TODO define deploy workflow here"

