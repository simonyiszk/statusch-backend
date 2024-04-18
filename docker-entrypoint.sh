#!/bin/ash
cd /opt/app/statusch_backend || exit
python manage.py migrate                  # Apply database migrations
python manage.py collectstatic --noinput  # Collect static files

# Start Gunicorn processes
echo Starting Gunicorn.
gunicorn statusch.wsgi:application \
    --name statusch \
    --bind 0.0.0.0:8000 \
    --workers 10 \
    --timeout 120 \
    --log-level=info

"$@"
