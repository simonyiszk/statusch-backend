#!/bin/ash
cd /opt/app/statusch_backend || exit
python manage.py migrate                  # Apply database migrations
python manage.py collectstatic --noinput  # Collect static files
python manage.py runserver 0.0.0.0:8000
"$@"
