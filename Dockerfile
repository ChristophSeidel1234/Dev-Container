# Base Image with Python and GPU support
FROM nvidia/cuda:12.2.0-runtime-ubuntu22.04 AS base

# Set environment variables for Python
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DEBIAN_FRONTEND=noninteractive

# Install system dependencies and Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv build-essential curl git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Code-Server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Create a user for Code-Server
RUN useradd -m coder && mkdir -p /home/coder/project && chown -R coder:coder /home/coder

# Switch to the new user
USER coder
WORKDIR /home/coder/project

# Install Python dependencies
COPY requirements.txt /home/coder/project/requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose ports for Code-Server
EXPOSE 8080

# Start Code-Server
CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "none"]
