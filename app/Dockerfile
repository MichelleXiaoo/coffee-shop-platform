FROM python:3.12-slim

# Don't buffer stdout. Logs appear immediately (matters for CloudWatch later)
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Copy deps first so this layer caches when only app code changes
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Run as a non-root user
RUN useradd --create-home appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8080

# gunicorn, not Flask's dev server
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]
