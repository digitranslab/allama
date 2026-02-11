# Allama Development Makefile

-include .env
export

.PHONY: init default test test-fast test-temporal bench down clean clean-images clean-dangling \
        dev dev-ui build-dev local build-local rebuild-local up build \
        lint-ui lint-app lint-fix-ui lint-fix-app lint lint-fix fix \
        typecheck gen-client gen-client-ci update-version \
        temporal-stop-all cluster

# Generate .env from .env.example with fresh secrets
# Usage: make init [ADMIN_EMAIL=you@example.com]
ADMIN_EMAIL ?= admin@example.com
init:
	@if [ -f .env ]; then \
		echo ".env already exists. Remove it first if you want to regenerate."; \
		exit 1; \
	fi
	@echo "Generating .env from .env.example..."
	@cp .env.example .env
	@DB_KEY=$$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())" 2>/dev/null || \
		python3 -c "import base64, os; print(base64.urlsafe_b64encode(os.urandom(32)).decode())") && \
	SVC_KEY=$$(openssl rand -hex 32) && \
	SIGN_KEY=$$(openssl rand -hex 32) && \
	AUTH_KEY=$$(openssl rand -hex 32) && \
	sed -i.bak \
		-e "s|ALLAMA__DB_ENCRYPTION_KEY=.*|ALLAMA__DB_ENCRYPTION_KEY=$$DB_KEY|" \
		-e "s|ALLAMA__SERVICE_KEY=.*|ALLAMA__SERVICE_KEY=$$SVC_KEY|" \
		-e "s|ALLAMA__SIGNING_SECRET=.*|ALLAMA__SIGNING_SECRET=$$SIGN_KEY|" \
		-e "s|USER_AUTH_SECRET=.*|USER_AUTH_SECRET=$$AUTH_KEY|" \
		-e "s|ALLAMA__AUTH_SUPERADMIN_EMAIL=.*|ALLAMA__AUTH_SUPERADMIN_EMAIL=$(ADMIN_EMAIL)|" \
		.env && \
	rm -f .env.bak
	@echo "Done. .env created with fresh secrets and admin email: $(ADMIN_EMAIL)"

default:
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*' Makefile | grep -v '^\.' | sed 's/:.*//' | sort | column

test:
	pytest --cache-clear tests/registry tests/unit tests/playbooks -x

test-fast:
	uv run pytest tests/unit -m "not (slow or integration or temporal)" -n auto -x

test-temporal:
	uv run pytest tests/temporal -x

# Run specific test file with parallel execution
# Usage: make test-file FILE=path/to/test.py
test-file:
	uv run pytest $(FILE) -n auto -x

# Run tests matching a keyword
# Usage: make test-k KEYWORD=my_keyword
test-k:
	uv run pytest tests/unit -k "$(KEYWORD)" -n auto -x

# Run backend benchmarks inside Docker (required for nsjail on macOS)
# Usage: make bench ARGS="extra args"
bench:
	docker run --rm \
		--network allama_default \
		--cap-add SYS_ADMIN \
		--security-opt seccomp=unconfined \
		--env-file .env \
		-e REDIS_URL=redis://redis:6379 \
		-e ALLAMA__BLOB_STORAGE_ENDPOINT=http://minio:9000 \
		-e ALLAMA__DB_URI=postgresql+psycopg://postgres:postgres@postgres_db:5432/postgres \
		-v "$$(pwd)/tests:/app/tests:ro" \
		--entrypoint sh \
		allama-executor \
		-c "pip install pytest pytest-anyio anyio -q && python -m pytest tests/backends/test_backend_benchmarks.py -v -s $(ARGS)"

down:
	docker compose down --remove-orphans

clean:
	docker volume ls -q | xargs -r docker volume rm

clean-images:
	docker images --filter "reference=allama*" | awk 'NR>1 && $$1 != "<none>" && $$2 != "<none>" {print $$1 ":" $$2}' | xargs -r -n 1 docker rmi

clean-dangling:
	docker image prune -f

dev:
	docker compose -f docker-compose.dev.yml up

dev-ui:
	npx @agentdeskai/browser-tools-server@1.2.0

# Build dev images. Usage: make build-dev SERVICES="api worker"
build-dev:
	docker compose -f docker-compose.dev.yml build --no-cache $(SERVICES)

local:
	NODE_ENV=production NEXT_PUBLIC_APP_ENV=production ALLAMA__APP_ENV=production docker compose -f docker-compose.local.yml up

# Usage: make build-local SERVICES="api"
build-local:
	docker compose -f docker-compose.local.yml build $(SERVICES)

# Usage: make rebuild-local SERVICES="api"
rebuild-local:
	docker compose -f docker-compose.local.yml build --no-cache $(SERVICES)

up:
	docker compose up

build:
	docker compose build --no-cache

lint-ui:
	pnpm -C frontend lint:fix

lint-app:
	uv run ruff check

lint-fix-ui:
	pnpm -C frontend check

lint-fix-app:
	uv run ruff check . --fix && uv run ruff format .

lint: lint-ui lint-app

lint-fix: lint-fix-ui lint-fix-app

fix: lint-fix

typecheck:
	uv run basedpyright --warnings --threads 4

gen-client:
	pnpm -C frontend generate-client
	$(MAKE) lint-fix

gen-client-ci:
	pnpm -C frontend generate-client-ci
	$(MAKE) lint-fix

# Update version number. Usage: make update-version AFTER=1.2.3
update-version:
	@-./scripts/update-version.sh $(AFTER)

# Stop all running Temporal workflow executions
temporal-stop-all:
	@command -v temporal >/dev/null 2>&1 || { echo "Error: Temporal CLI is not installed"; exit 1; }
	temporal workflow terminate --query "ExecutionStatus='Running'" --namespace default --yes

# Manage multiple Allama clusters. Usage: make cluster ARGS="up -d"
cluster:
	./scripts/cluster $(ARGS)
