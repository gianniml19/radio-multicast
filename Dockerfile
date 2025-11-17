FROM debian:bookworm-slim

# ffmpeg + benötigte Tools installieren
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        ca-certificates \
        bash \
        sed && \
    rm -rf /var/lib/apt/lists/*

# Startskript ins Image
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Arbeitsverzeichnis für Playlist + evtl. Dateien
WORKDIR /data

# Standard-Einstiegspunkt
ENTRYPOINT ["/usr/local/bin/start.sh"]
