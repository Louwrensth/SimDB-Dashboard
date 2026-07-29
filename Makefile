SHELL := /bin/sh

VERSION ?= $(shell git describe --tags --always 2>/dev/null || echo 0.0.0-unknown)
DASHBOARD_PORT ?= 80
COMPOSE_PROJECT_NAME ?= simdb-dashboard-$(DASHBOARD_PORT)

ifeq ($(USE_HTTPS),1)
DASHBOARD_HTTPS_PORT ?= 443
export DASHBOARD_HTTPS_PORT
COMPOSE_FILE ?= docker-compose.yml:docker-compose-https.yml
SERVICE_IMAGE := simdb-dashboard:service-https
else
COMPOSE_FILE ?= docker-compose.yml
SERVICE_IMAGE := simdb-dashboard:service
endif

export DASHBOARD_PORT
export COMPOSE_PROJECT_NAME

DOCKER_CMD ?= docker
DOCKER_BUILD ?= $(DOCKER_CMD) build --build-arg APP_VERSION="$(VERSION)"
DOCKER_COMPOSE ?= APP_VERSION="$(VERSION)" COMPOSE_FILE="$(COMPOSE_FILE)" $(DOCKER_CMD) compose

BUILD_IMAGE := simdb-dashboard:build
DEV_IMAGE := simdb-dashboard:dev

.DEFAULT_GOAL := service

.PHONY: \
	build \
	builder \
	clean-images \
	deploy \
	dev \
	dist \
	distclean \
	down \
	help \
	lint \
	list \
	list-all \
	logs-f \
	service \
	shell \
	systemd-disable \
	systemd-enable \
	systemd-install \
	systemd-start \
	systemd-stop \
	systemd-uninstall \
	test \
	type-check \
	up \
	update-base \
	update-deps \
	version

help:
	@echo "Core workflow:"
	@echo "  make service         Build and tag final service image"
	@echo ""
	@echo "Compose service (make service first):"
	@echo "  make up              Start simdb-dashboard service using prebuilt service image"
	@echo "  make down            Stop simdb-dashboard service"
	@echo "  make list            List container matching the selected DASHBOARD_PORT"
	@echo "  make list-all        List all simdb-dashboard-* containers"
	@echo "  make logs-f          Follow logs of the started simdb-dashboard service"
	@echo "  make shell           Enter shell in the started simdb-dashboard service"
	@echo ""
	@echo "HTTPS toggle (set USE_HTTPS=1):"
	@echo "  USE_HTTPS=1 make service   Build HTTPS service stage and tag simdb-dashboard:service-https"
	@echo "  USE_HTTPS=1 make up        Start dashboard with docker-compose-https.yml override"
	@echo "  USE_HTTPS=1 make down      Stop dashboard started with the HTTPS compose override"
	@echo "  USE_HTTPS=1 make logs-f    Follow logs of the HTTPS compose service"
	@echo "  USE_HTTPS=1 make shell     Enter shell in the started HTTPS compose service"
	@echo ""
	@echo "Dockerfile stage targets:"
	@echo "  make builder         Build builder stage (dependency setup + source prep)"
	@echo "  make build           Build application build stage and tag $(BUILD_IMAGE)"
	@echo ""
	@echo "Developer utilities:"
	@echo "  make lint            Run lint checks against the build image (make build first)"
	@echo "  make type-check      Run TypeScript type checks against the build image (make build first)"
	@echo "  make test            Run unit tests against the build image (make build first)"
	@echo "  make dev             Run Vite dev server from Docker dev stage with live local changes"
	@echo "  make version         Show git-derived application version"
	@echo ""
	@echo "Artifacts and maintenance:"
	@echo "  make simdb-dashboard-service.tar    Export runnable service image"
	@echo "  make dist            Export Single Page Application artifact to ./dist/"
	@echo "  make update-base     Rebuild service image pulling latest base images"
	@echo "  make update-deps     Update npm lockfile and audit-fix deps via Docker"
	@echo "  make distclean       Remove local artifacts and compose runtime state"
	@echo "  make deploy          Deploy project (placeholder)"
	@echo ""
	@echo "Systemd integration (run with sudo):"
	@echo "  sudo make systemd-install    Copy files to /opt/simdb-dashboard and /etc/simdb-dashboard"
	@echo "  sudo make systemd-enable     systemctl daemon-reload, enable, and start the service"
	@echo "  sudo make systemd-start      systemctl start  simdb-dashboard"
	@echo "  sudo make systemd-stop       systemctl stop   simdb-dashboard"
	@echo "  sudo make systemd-disable    systemctl stop && systemctl disable simdb-dashboard"
	@echo "  sudo make systemd-uninstall  Disable, remove unit file, delete /opt/ and /etc/ files"
	@echo "  USE_HTTPS=1 sudo make systemd-install  Include HTTPS compose override and SSL setup"
	@echo ""
	@echo "Environment variable examples:"
	@echo "  Start simdb-dashboard at alternative DASHBOARD_PORT, with simdb server at API_PORT:"
	@echo "    DASHBOARD_PORT=8080 API_PORT=5100 make up"
	@echo "  Start HTTPS dashboard with alternative HTTP/HTTPS host ports:"
	@echo "    DASHBOARD_PORT=8080 DASHBOARD_HTTPS_PORT=8443 USE_HTTPS=1 make up"

# Compose targets
up:
	$(DOCKER_COMPOSE) up -d --no-build

down:
	$(DOCKER_COMPOSE) down

list:
	$(DOCKER_CMD) ps \
		--filter "label=com.docker.compose.project=$(COMPOSE_PROJECT_NAME)" \
		--filter "label=io.simdb.component=dashboard"

list-all:
	$(DOCKER_CMD) ps --filter "label=io.simdb.component=dashboard"

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

simdb-dashboard-service.tar: service
	$(DOCKER_CMD) save -o simdb-dashboard-service.tar $(SERVICE_IMAGE)
	@echo "Service image exported: simdb-dashboard-service.tar"
	@echo "To load and run the image:"
	@echo "  docker load -i simdb-dashboard-service.tar"
	@echo "  docker run --rm -p 8080:80 --add-host host.docker.internal:host-gateway simdb-dashboard:service"

update-base:
	$(DOCKER_BUILD) --no-cache --pull --target service -t $(SERVICE_IMAGE) .

update-deps: dashboard/package-lock.json

# File target: only runs if package-lock.json is missing or older than package.json.
dashboard/package-lock.json: dashboard/package.json
	$(DOCKER_CMD) run --rm -v "$(PWD)/dashboard":/app -w /app node:24-alpine sh -c \
		"npm install --package-lock-only && npm audit fix && npm list"

distclean:
	APP_VERSION="$(VERSION)" COMPOSE_FILE="docker-compose.yml" $(DOCKER_CMD) compose down --volumes --remove-orphans --rmi local
	APP_VERSION="$(VERSION)" COMPOSE_FILE="docker-compose.yml:docker-compose-https.yml" $(DOCKER_CMD) compose down --volumes --remove-orphans --rmi local
	$(DOCKER_CMD) rmi -f $(BUILD_IMAGE) simdb-dashboard:service simdb-dashboard:service-https >/dev/null 2>&1 || true
	$(DOCKER_CMD) volume rm -f simdb_dashboard_node_modules >/dev/null 2>&1 || true
	rm -rf dist

# Systemd integration (run with sudo)
systemd-install:
	mkdir -p /opt/simdb-dashboard
	cp docker-compose.yml /opt/simdb-dashboard/
	cp docker-compose.systemd.yml /opt/simdb-dashboard/
	cp -r docker/nginx/templates /opt/simdb-dashboard/
	mkdir -p /etc/simdb-dashboard
	[ -f /etc/simdb-dashboard/simdb-dashboard.env ] || \
		{ echo '# Created by make systemd-install' > /etc/simdb-dashboard/simdb-dashboard.env; \
		  echo 'API_HOST=host.docker.internal' >> /etc/simdb-dashboard/simdb-dashboard.env; \
		  echo 'SIMDB_SERVER_URL=/scenarios/api' >> /etc/simdb-dashboard/simdb-dashboard.env; }
ifeq ($(USE_HTTPS),1)
	cp docker-compose-https.yml /opt/simdb-dashboard/
	mkdir -p /etc/ssl/simdb-dashboard
	cp docker/nginx/ssl/cert.* /etc/ssl/simdb-dashboard/ 2>/dev/null || \
		echo "  *** No certificate files found at docker/nginx/ssl/ — generate them with:"; \
		echo "  ***   scripts/generate-self-signed-certs.sh"; \
		echo "  ***   cp docker/nginx/ssl/cert.* /etc/ssl/simdb-dashboard/"
	mkdir -p /opt/simdb-dashboard/docker/nginx
	ln -sf /etc/ssl/simdb-dashboard /opt/simdb-dashboard/docker/nginx/ssl
endif

systemd-enable:
	systemctl daemon-reload
	systemctl enable simdb-dashboard
	systemctl start simdb-dashboard

systemd-start:
	systemctl start simdb-dashboard

systemd-stop:
	systemctl stop simdb-dashboard

systemd-disable: systemd-stop
	systemctl disable simdb-dashboard

systemd-uninstall: systemd-disable
	rm -f /etc/systemd/system/simdb-dashboard.service
	systemctl daemon-reload
	rm -rf /opt/simdb-dashboard
	rm -rf /etc/simdb-dashboard
	[ ! -e /etc/ssl/simdb-dashboard ] || rm -rf /etc/ssl/simdb-dashboard

# Deployment
deploy:
	@echo "TODO define deploy workflow here"

