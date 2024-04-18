FROM python:3.11.4-alpine as base
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_VERSION=1.7.1 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    POETRY_INSTALLER_MAX_WORKERS=20 \
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv" \
    POETRY_VIRTUALENVS_CREATE=true
ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

# Lets do a builder image
FROM base as builder
# Install stuff
RUN apk add --no-cache curl build-base libffi-dev && \
  curl -sSL https://install.python-poetry.org | python3
WORKDIR $PYSETUP_PATH
COPY pyproject.toml poetry.lock $PYSETUP_PATH/
RUN poetry install --no-directory --no-cache --no-interaction -vvv

# Create prod image
FROM base as prod
COPY --from=builder $VENV_PATH $VENV_PATH
COPY docker-entrypoint.sh /opt/app/
COPY pyproject.toml /opt/app/
COPY statusch_backend /opt/app/statusch_backend
ENV ENV_PATH .env
EXPOSE 8000
WORKDIR /opt/app/statusch_backend/
ENTRYPOINT ["/opt/app/docker-entrypoint.sh"]
