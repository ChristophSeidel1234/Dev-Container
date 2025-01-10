# Base Image for Python and system dependencies
FROM python:3.11-slim AS python-base

# Set environment variables for Python
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Install basic system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gnupg build-essential \
    build-essential \
    libpython3.11 \
    libpython3.11-dev \
    curl \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Füge NVIDIA-Repository hinzu
RUN curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && \
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list && \
    apt-get update && \
    apt-get install -y nvidia-container-toolkit && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Installiere Pip, falls es nicht schon da ist
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python get-pip.py \
    && rm get-pip.py

# Setze Arbeitsverzeichnis für Code
WORKDIR /home/coder

# Install Python dependencies
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Stage 2: Jupyter-basierte Umgebung
FROM jupyter/base-notebook:latest AS jupyter-base

# Kopiere Python-Pakete und Abhängigkeiten aus Stage 1
COPY --from=python-base /usr/local/lib/python3.11 /usr/local/lib/python3.11
COPY --from=python-base /usr/local/bin /usr/local/bin

# Installiere zusätzliche Abhängigkeiten für Jupyter und R
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    r-base \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Nutzer zurücksetzen
USER $NB_UID

# Stage 3: Finales Image mit Code-Server
FROM codercom/code-server:latest AS code-server-base

# Kopiere Pip von python-base Stage
COPY --from=python-base /usr/local /usr/local

# Kopiere Python- und Jupyter-Umgebungen aus den vorherigen Stages
COPY --from=jupyter-base /usr/local /usr/local
COPY --from=jupyter-base /home/jovyan /home/coder

# Erstelle und setze ein Volume, das Pakete persistent speichert
VOLUME /home/coder/.local

# Stelle sicher, dass der Benutzer coder Zugriff auf /home/coder/.local hat
RUN mkdir -p /home/coder/.local && chown -R coder:coder /home/coder/.local

# Installiere zusätzliche Abhängigkeiten für Code-Server
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    libsqlite3-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Nutzer zurücksetzen
USER coder

# Expose required ports
EXPOSE 8080 8888

# Start both Code-Server and Jupyter
CMD ["sh", "tini -g -- code-server --bind-addr 0.0.0.0:8080 --auth none & \
                   jupyter notebook --ip=0.0.0.0 --no-browser --allow-root --port=8888"]
