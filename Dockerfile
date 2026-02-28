# Stage 1: Build stage
FROM python:3.10-slim AS builder

WORKDIR /app

# Install necessary building tools
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip
COPY requirements.txt .
# Install into a designated folder
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt
RUN pip install --no-cache-dir --prefix=/install django-rq rq-scheduler rq

# Stage 2: Final Production stage
FROM python:3.10-slim

# Creating a new user for security reasons
RUN useradd -m -r appuser && \
    mkdir /app && \
    chown -R appuser /app

# Install library for Postgresql
RUN apt-get update && apt-get install -y \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the installations from building stage
COPY --from=builder /install /usr/local

# Copy the code under the new user permissions
COPY --chown=appuser:appuser . .

WORKDIR /app/statuspage

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Run the app as the new user
USER appuser

# Collect static files for WhiteNoise
RUN SECRET_KEY="dummy_build_key" python manage.py collectstatic --noinput

EXPOSE 8000

# The command that runs the app
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "statuspage.wsgi:application"]