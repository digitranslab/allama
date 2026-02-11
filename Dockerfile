# ---- Stage 1: Build nsjail (sandbox isolation) ----
FROM debian:bookworm-slim AS nsjail-builder

ENV DEBIAN_FRONTEND=noninteractive
ENV NSJAIL_COMMIT=b24be32d38a26656568491c2c5fcffa6e77341d6

RUN apt-get update && apt-get install -y --no-install-recommends \
    git gcc g++ make pkg-config bison flex \
    libprotobuf-dev protobuf-compiler libnl-route-3-dev ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/google/nsjail.git /tmp/nsjail && \
    cd /tmp/nsjail && git checkout "${NSJAIL_COMMIT}" && \
    git submodule update --init --recursive && \
    make -j"$(nproc)" && \
    install -m 0755 nsjail /usr/local/bin/nsjail && \
    rm -rf /tmp/nsjail

# ---- Stage 2: Sandbox rootfs (minimal Python environment for isolated execution) ----
FROM python:3.12-slim-bookworm AS sandbox-rootfs

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget jq iputils-ping && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:0.9.15 /uv /usr/local/bin/uv

RUN useradd -m -u 1000 sandbox && \
    mkdir -p /workspace /work /cache /packages /home/sandbox && \
    chown sandbox:sandbox /workspace /work /cache /packages /home/sandbox

ENV HOME=/tmp PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

# ---- Stage 3: Shared base (runtime deps, nsjail, sandbox rootfs) ----
FROM ghcr.io/astral-sh/uv:0.9.15-python3.12-bookworm-slim AS base

ENV HOST=0.0.0.0 PORT=8000

COPY --from=nsjail-builder /usr/local/bin/nsjail /usr/local/bin/nsjail

RUN apt-get update && apt-get install -y --no-install-recommends \
    acl git openssh-client xmlsec1 libmagic1 curl ca-certificates \
    libnl-route-3-200 libprotobuf32 \
    passt \
    && apt-get -y upgrade \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy sandbox rootfs layers
COPY --from=sandbox-rootfs /usr /var/lib/allama/sandbox-rootfs/usr
COPY --from=sandbox-rootfs /lib /var/lib/allama/sandbox-rootfs/lib
COPY --from=sandbox-rootfs /bin /var/lib/allama/sandbox-rootfs/bin
COPY --from=sandbox-rootfs /sbin /var/lib/allama/sandbox-rootfs/sbin
COPY --from=sandbox-rootfs /etc/passwd /var/lib/allama/sandbox-rootfs/etc/passwd
COPY --from=sandbox-rootfs /etc/group /var/lib/allama/sandbox-rootfs/etc/group
COPY --from=sandbox-rootfs /etc/ssl /var/lib/allama/sandbox-rootfs/etc/ssl
COPY --from=sandbox-rootfs /etc/ca-certificates /var/lib/allama/sandbox-rootfs/etc/ca-certificates
RUN install -m 0644 /dev/null /var/lib/allama/sandbox-rootfs/etc/resolv.conf && \
    install -m 0644 /dev/null /var/lib/allama/sandbox-rootfs/etc/hosts && \
    install -m 0644 /dev/null /var/lib/allama/sandbox-rootfs/etc/nsswitch.conf

# lib64 only exists on amd64
RUN if [ -d /var/lib/allama/sandbox-rootfs/lib64 ] || [ "$(uname -m)" = "x86_64" ]; then \
        mkdir -p /var/lib/allama/sandbox-rootfs/lib64 && \
        cp -a /lib64/. /var/lib/allama/sandbox-rootfs/lib64/ 2>/dev/null || true; \
    fi

# Sandbox mount points and permissions
RUN mkdir -p /var/lib/allama/sandbox-rootfs/tmp \
    /var/lib/allama/sandbox-rootfs/proc \
    /var/lib/allama/sandbox-rootfs/dev \
    /var/lib/allama/sandbox-rootfs/work \
    /var/lib/allama/sandbox-rootfs/cache \
    /var/lib/allama/sandbox-rootfs/packages \
    /var/lib/allama/sandbox-rootfs/home/sandbox \
    /var/lib/allama/sandbox-cache/packages \
    /var/lib/allama/sandbox-cache/uv-cache && \
    chmod -R 755 /var/lib/allama/sandbox-rootfs && \
    chown -R 1000:1000 /var/lib/allama/sandbox-rootfs/work \
        /var/lib/allama/sandbox-rootfs/cache \
        /var/lib/allama/sandbox-rootfs/packages \
        /var/lib/allama/sandbox-rootfs/home/sandbox && \
    chmod 1777 /var/lib/allama/sandbox-rootfs/tmp

# Non-root user (uid 1001 required for pasta networking)
RUN groupadd -g 1001 apiuser && useradd -m -u 1001 -g apiuser apiuser && \
    mkdir -p /home/apiuser/.cache/uv /home/apiuser/.cache/s3 /home/apiuser/.cache/tmp /home/apiuser/.local/bin && \
    chown -R apiuser:apiuser /home/apiuser

WORKDIR /app

# ---- Stage 4: Development ----
FROM base AS development

ENV TMPDIR=/tmp TEMP=/tmp TMP=/tmp

RUN chown -R 1001:1001 /var/lib/allama/sandbox-cache && \
    chmod -R 755 /var/lib/allama/sandbox-cache

# MCP socket dir
RUN mkdir -p /var/run/allama && chown 1001:1001 /var/run/allama

# Install deps (cached layer, before copying source)
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=packages,target=packages \
    uv sync --locked --no-install-project --no-dev --no-editable

COPY --chown=apiuser:apiuser . /app/

RUN --mount=type=cache,target=/root/.cache/uv uv sync --frozen --no-dev

RUN chown -R apiuser:apiuser /app

ENV PATH="/app/.venv/bin:$PATH"

RUN mkdir -p /home/apiuser/.local/bin && ln -s $(which uv) /home/apiuser/.local/bin/uv

COPY docker/scripts/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

USER apiuser

ENTRYPOINT ["/app/entrypoint.sh"]
EXPOSE $PORT
CMD ["sh", "-c", "python3 -m uvicorn allama.api.app:app --host $HOST --port $PORT --reload"]

# ---- Stage 5: Test (development + pytest) ----
FROM development AS test

RUN --mount=type=cache,target=/home/apiuser/.cache/uv,uid=1001,gid=1001 uv sync --frozen --group dev

CMD ["python", "-m", "pytest"]

# ---- Stage 6: Production ----
FROM base AS production

ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy

RUN chown -R 1001:1001 /var/lib/allama/sandbox-cache && \
    chmod -R 755 /var/lib/allama/sandbox-cache

COPY docker/scripts/auto-update.sh ./auto-update.sh
RUN chmod +x auto-update.sh && ./auto-update.sh && rm auto-update.sh

ENV PYTHONUSERBASE="/home/apiuser/.local"
ENV UV_CACHE_DIR="/home/apiuser/.cache/uv"
ENV PYTHONPATH="/home/apiuser/.local"
ENV PATH="/home/apiuser/.local/bin:/usr/local/bin:/usr/bin:/bin"
ENV TMPDIR="/home/apiuser/.cache/tmp" TEMP="/home/apiuser/.cache/tmp" TMP="/home/apiuser/.cache/tmp"

RUN mkdir -p /app/.scripts && chown -R apiuser:apiuser /app

USER apiuser

# Install deps as non-root
RUN --mount=type=cache,target=/home/apiuser/.cache/uv,uid=1001,gid=1001 \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=packages,target=packages \
    uv sync --locked --no-install-project --no-dev --no-editable

COPY --chown=apiuser:apiuser ./allama /app/allama
COPY --chown=apiuser:apiuser ./packages /app/packages
COPY --chown=apiuser:apiuser ./pyproject.toml ./uv.lock ./.python-version ./README.md ./LICENSE ./alembic.ini /app/
COPY --chown=apiuser:apiuser ./alembic /app/alembic
COPY --chown=apiuser:apiuser docker/scripts/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

RUN --mount=type=cache,target=/home/apiuser/.cache/uv,uid=1001,gid=1001 \
    uv sync --locked --no-dev --no-editable

ENV PATH="/app/.venv/bin:/home/apiuser/.local/bin:/usr/local/bin:/usr/bin:/bin"

RUN ln -sf $(which uv) /home/apiuser/.local/bin/uv

RUN nsjail --help > /dev/null 2>&1 && echo "nsjail available"

EXPOSE $PORT
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["sh", "-c", "python3 -m uvicorn allama.api.app:app --host $HOST --port $PORT"]
