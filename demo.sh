#!/bin/bash
set -e

# Allama Demo Setup Script
# This script builds the app locally from scratch and creates an admin user
# Run: ./demo.sh

echo "=========================================="
echo "  Allama Demo Setup"
echo "=========================================="

# Configuration
ADMIN_EMAIL="admin@example.com"
ADMIN_PASSWORD="AdminPassword123!"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    echo ""
    echo "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    print_status "Docker is installed"
    
    if ! command -v docker compose &> /dev/null; then
        print_error "Docker Compose is not installed"
        exit 1
    fi
    print_status "Docker Compose is installed"
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        exit 1
    fi
    print_status "Docker daemon is running"
    
    # Check for Python (needed for Fernet key generation)
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 is not installed (needed for Fernet key generation)"
        exit 1
    fi
    print_status "Python3 is installed"
}

# Generate hex secret
generate_hex_secret() {
    openssl rand -hex 32
}

# Generate Fernet key using Python
generate_fernet_key() {
    python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())" 2>/dev/null || \
    python3 -c "import base64, os; print(base64.urlsafe_b64encode(os.urandom(32)).decode())"
}

# Create .env file from scratch
create_env_file() {
    echo ""
    echo "Creating .env file from scratch..."
    
    # Generate all secrets
    print_info "Generating secrets..."
    SERVICE_KEY=$(generate_hex_secret)
    SIGNING_SECRET=$(generate_hex_secret)
    USER_AUTH_SECRET=$(generate_hex_secret)
    
    # Generate Fernet key for DB encryption
    DB_ENCRYPTION_KEY=$(generate_fernet_key)
    
    print_status "Generated SERVICE_KEY"
    print_status "Generated SIGNING_SECRET"
    print_status "Generated USER_AUTH_SECRET"
    print_status "Generated DB_ENCRYPTION_KEY (Fernet)"
    
    # Remove existing .env if present
    if [ -f .env ]; then
        print_warning "Removing existing .env file"
        rm -f .env
    fi
    
    # Create new .env file
    cat > .env << EOF
# --- Shared env vars ---
LOG_LEVEL=INFO
COMPOSE_PROJECT_NAME=allama
COMPOSE_BAKE=true

# --- Network configuration ---
PUBLIC_APP_PORT=80
PUBLIC_APP_URL=http://localhost:\${PUBLIC_APP_PORT}
PUBLIC_API_URL=\${PUBLIC_APP_URL}/api
INTERNAL_API_URL=http://api:8000

# -- Caddy env vars ---
BASE_DOMAIN=:\${PUBLIC_APP_PORT}
ADDRESS=0.0.0.0

# --- Frontend env vars ---
NODE_ENV=development
NEXT_PUBLIC_APP_ENV=development
NEXT_PUBLIC_APP_URL=\${PUBLIC_APP_URL}
NEXT_PUBLIC_API_URL=\${PUBLIC_API_URL}
NEXT_SERVER_API_URL=\${INTERNAL_API_URL}

# --- App and DB env vars ---
ALLAMA__APP_ENV=development
ALLAMA__DB_ENCRYPTION_KEY=${DB_ENCRYPTION_KEY}
ALLAMA__SERVICE_KEY=${SERVICE_KEY}
ALLAMA__EXECUTOR_TOKEN_TTL_SECONDS=900
ALLAMA__SIGNING_SECRET=${SIGNING_SECRET}
ALLAMA__API_URL=\${INTERNAL_API_URL}
ALLAMA__API_ROOT_PATH=/api
ALLAMA__PUBLIC_APP_URL=\${PUBLIC_APP_URL}
ALLAMA__PUBLIC_API_URL=\${PUBLIC_API_URL}
ALLAMA__ALLOW_ORIGINS=http://localhost:3000,\${PUBLIC_APP_URL}
ALLAMA__DB_SSLMODE=disable

# --- Postgres ---
ALLAMA__POSTGRES_USER=postgres
ALLAMA__POSTGRES_PASSWORD=postgres
ALLAMA__DB_URI=postgresql+psycopg://\${ALLAMA__POSTGRES_USER}:\${ALLAMA__POSTGRES_PASSWORD}@postgres_db:5432/postgres

# --- Authentication ---
ALLAMA__AUTH_SUPERADMIN_EMAIL=${ADMIN_EMAIL}
ALLAMA__AUTH_TYPES=basic,google_oauth
ALLAMA__AUTH_ALLOWED_DOMAINS=
ALLAMA__AUTH_MIN_PASSWORD_LENGTH=12
OAUTH_CLIENT_ID=
OAUTH_CLIENT_SECRET=
USER_AUTH_SECRET=${USER_AUTH_SECRET}

# SAML SSO settings
SAML_IDP_METADATA_URL=
SAML_ACCEPTED_TIME_DIFF=3

# --- Temporal ---
TEMPORAL__CLUSTER_URL=temporal:7233
TEMPORAL__CLUSTER_QUEUE=allama-task-queue
TEMPORAL__CLUSTER_NAMESPACE=default
TEMPORAL__POSTGRES_USER=temporal
TEMPORAL__POSTGRES_PASSWORD=temporal
TEMPORAL__UI_VERSION=latest
TEMPORAL__API_KEY=

# --- Workflow Artifacts ---
ALLAMA__WORKFLOW_ARTIFACT_RETENTION_DAYS=30

# --- MinIO ---
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin

# --- Redis ---
REDIS_URL=redis://redis:6379

# --- Cloud only ---
NEXT_PUBLIC_POSTHOG_KEY=
NEXT_PUBLIC_POSTHOG_HOST=https://us.i.posthog.com
NEXT_PUBLIC_DISABLE_SESSION_RECORDING=true

# --- Local registry ---
ALLAMA__LOCAL_REPOSITORY_ENABLED=false
ALLAMA__LOCAL_REPOSITORY_PATH=~/dev/org/internal-registry

# --- Enterprise Features (all enabled) ---
ALLAMA__FEATURE_FLAGS=git-sync,agent-approvals,agent-presets,case-durations,case-tasks
EOF

    print_status "Created .env file with all required configuration"
}

# Stop and remove all existing containers and volumes
cleanup() {
    echo ""
    echo "Cleaning up existing containers and volumes..."
    
    # Stop any running allama containers (all possible project names)
    print_info "Stopping any running Allama containers..."
    
    # Find and stop all allama-related containers
    docker ps -a --format '{{.Names}}' | grep -E "allama" | xargs -r docker stop 2>/dev/null || true
    docker ps -a --format '{{.Names}}' | grep -E "allama" | xargs -r docker rm -f 2>/dev/null || true
    
    # Stop using docker compose with various project names
    docker compose -f docker-compose.dev.yml down -v --remove-orphans 2>/dev/null || true
    docker compose -f docker-compose.yml down -v --remove-orphans 2>/dev/null || true
    docker compose -f docker-compose.local.yml down -v --remove-orphans 2>/dev/null || true
    
    # Try with explicit project names that might exist
    for project in allama allama-main-1 allama-dev; do
        docker compose -p "$project" down -v --remove-orphans 2>/dev/null || true
    done
    
    # Also try with the cluster script if it exists
    if [ -f ./scripts/cluster ]; then
        print_info "Stopping cluster via scripts/cluster..."
        ./scripts/cluster down 2>/dev/null || true
    fi
    
    # Remove all allama-related volumes
    print_info "Removing Allama volumes..."
    docker volume ls -q | grep -E "allama|core-db|temporal-db|minio-data|redis-data|sandbox-cache" | xargs -r docker volume rm -f 2>/dev/null || true
    
    # Remove all allama-related networks
    print_info "Removing Allama networks..."
    docker network ls -q --filter "name=allama" | xargs -r docker network rm 2>/dev/null || true
    
    # Prune any dangling resources
    docker system prune -f 2>/dev/null || true
    
    print_status "Cleaned up all existing containers, volumes, and networks"
}

# Build and start services
start_services() {
    echo ""
    echo "Building and starting services (this may take several minutes)..."
    
    # Build UI container with no cache to ensure fresh dependencies
    print_info "Building UI container..."
    docker compose -f docker-compose.dev.yml build --no-cache ui 2>&1 | tail -5
    print_status "Built UI container"
    
    # Start all services
    print_info "Starting all services..."
    docker compose -f docker-compose.dev.yml up -d
    print_status "Started all services"
}

# Wait for API to be healthy
wait_for_api() {
    echo ""
    echo "Waiting for API to be ready..."
    
    max_attempts=90
    attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost/api/health 2>/dev/null | grep -q "ok"; then
            echo ""
            print_status "API is healthy"
            return 0
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    echo ""
    print_error "API failed to become healthy after ${max_attempts} attempts"
    print_info "Check logs with: docker compose -f docker-compose.dev.yml logs api"
    exit 1
}

# Wait for UI to be ready
wait_for_ui() {
    echo ""
    echo "Waiting for UI to be ready..."
    
    max_attempts=60
    attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost 2>/dev/null | grep -q "html"; then
            echo ""
            print_status "UI is ready"
            return 0
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    echo ""
    print_warning "UI may still be compiling, but should be accessible soon"
}

# Create admin user
create_admin_user() {
    echo ""
    echo "Creating admin user..."
    
    # Wait a bit for the database to be fully ready
    sleep 3
    
    # Register the admin user
    response=$(curl -s -w "\n%{http_code}" -X POST http://localhost/api/auth/register \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"${ADMIN_EMAIL}\",\"password\":\"${ADMIN_PASSWORD}\"}" 2>/dev/null)
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "201" ] || [ "$http_code" = "200" ]; then
        print_status "Admin user created successfully"
        
        # Verify user is superuser
        if echo "$body" | grep -q '"is_superuser":true'; then
            print_status "User has superuser privileges"
        fi
        if echo "$body" | grep -q '"role":"admin"'; then
            print_status "User has admin role"
        fi
    elif echo "$body" | grep -q "already exists\|REGISTER_USER_ALREADY_EXISTS"; then
        print_warning "Admin user already exists"
    else
        print_error "Failed to create admin user"
        print_info "Response: $body"
        print_info "You may need to register manually at http://localhost/sign-up"
    fi
}

# Print summary
print_summary() {
    echo ""
    echo "=========================================="
    echo -e "${GREEN}  Allama Demo Ready!${NC}"
    echo "=========================================="
    echo ""
    echo "Access the application:"
    echo "  - UI:          http://localhost"
    echo "  - API Docs:    http://localhost/api/docs"
    echo "  - Temporal UI: http://localhost:8081"
    echo "  - MinIO:       http://localhost:9001 (minioadmin/minioadmin)"
    echo ""
    echo "Admin Credentials:"
    echo "  - Email:    ${ADMIN_EMAIL}"
    echo "  - Password: ${ADMIN_PASSWORD}"
    echo ""
    echo "Features enabled:"
    echo "  - allama-ee (Enterprise features)"
    echo "  - allama-admin (Admin panel)"
    echo "  - allama-registry (Action registry)"
    echo ""
    echo "Useful commands:"
    echo "  - Stop:  docker compose -f docker-compose.dev.yml down"
    echo "  - Logs:  docker compose -f docker-compose.dev.yml logs -f"
    echo "  - Reset: ./demo.sh (runs fresh setup)"
    echo ""
}

# Main execution
main() {
    check_prerequisites
    create_env_file
    cleanup
    start_services
    wait_for_api
    wait_for_ui
    create_admin_user
    print_summary
}

# Run main function
main "$@"
