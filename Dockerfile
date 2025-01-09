# Base Image for Python and system dependencies
FROM python:3.11-slim AS python-base

# Set environment variables for Python
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Install basic system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    r-base \
    tini \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# -----------------------------------------------------------------------------

# Base Image for Code-Server
FROM codercom/code-server:latest AS code-server-base

# Copy Python and Jupyter setup from python-base
COPY --from=python-base /usr/local /usr/local
COPY --from=python-base /usr/lib/R /usr/lib/R

# Expose required ports
EXPOSE 8080 8888

# Start both Code-Server and Jupyter
CMD ["sh", "tini -g -- code-server --bind-addr 0.0.0.0:8080 --auth none & \
                   jupyter notebook --ip=0.0.0.0 --no-browser --allow-root --port=8888"]
