FROM python:3.11.4-alpine

# Add packages
RUN apk add --no-cache --virtual .build-deps --update libffi-dev build-base postgresql-dev
#   apk add --no-cache --virtual .npm --update nodejs npm

#RUN pip install --upgrade setuptools wheel --no-cache-dir  && \
RUN pip install --upgrade pip && \
	pip install --upgrade poetry --no-cache-dir

# Copy app
# Generate requirements
WORKDIR /opt/app
COPY pyproject.toml /opt/app
RUN poetry export -f requirements.txt --without-hashes --output /opt/app/requirements.txt
RUN pip install -r /opt/app/requirements.txt --no-cache-dir && \
	pip install --upgrade gunicorn --no-cache-dir && \
	rm -rf /root/.cache && rm -rf /tmp/*

COPY . /opt/app/
ENV ENV_PATH .env
EXPOSE 8000
COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]