#!/usr/bin/env bash
# Liest eine M3U-Playlist und startet für jede Quelle einen ffmpeg-Prozess,
# der als Multicast-Stream ins Netz sendet.

# -u  -> Fehler bei Nutzung nicht gesetzter Variablen
# -o pipefail -> Fehler in Pipelines nicht ignoriere
set -uo pipefail

# Playlist-Pfad (Volume ins Container gemappt)
PLAYLIST="${PLAYLIST:-/data/stations.m3u}"

# Basis-Multicast-Adresse (z.B. 239.10.10 -> 239.10.10.1, .2, .3, ...)
BASE_ADDR="${BASE_ADDR:-239.10.10}"

# Fester UDP-Port, den alle Streams benutzen
PORT="${PORT:-5000}"

# Time To Live für Multicast-Pakete
TTL="${TTL:-5}"

# Maximale Anzahl an Streams aus der Playlist
MAX_STREAMS="${MAX_STREAMS:-20}"

if [[ ! -f "$PLAYLIST" ]]; then
  echo "Playlist $PLAYLIST nicht gefunden!" >&2
  exit 1
fi

echo "Starte Multicast-Streaming aus Playlist: $PLAYLIST"
echo "Multicast-Adressen: ${BASE_ADDR}.X"
echo "Port für alle Streams: $PORT"
echo "Max Streams: $MAX_STREAMS"

i=0

# Playlist: jede nicht-leere, nicht-#-Zeile ist eine Quelle (URL oder Datei)
while IFS= read -r line; do
  # Trim
  line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

  [[ -z "$line" ]] && continue        # leere Zeilen
  [[ "$line" =~ ^# ]] && continue     # Kommentare (#EXTM3U, #EXTINF, ...)

  ((i++))
  if (( i > MAX_STREAMS )); then
    echo "MAX_STREAMS=$MAX_STREAMS erreicht, weitere Einträge ignoriert." >&2
    break
  fi

  addr="${BASE_ADDR}.${i}"
  echo "[$i] Quelle: $line -> udp://${addr}:${PORT}"

  ffmpeg -re -i "$line" \
      -c copy \
      -f mpegts "udp://${addr}:${PORT}?ttl=${TTL}&pkt_size=1316" \
      -loglevel warning -nostats &

done < "$PLAYLIST"

echo "Alle ffmpeg-Prozesse wurden gestartet."
wait
