#!/bin/bash
# Generiert Blender-Script für Freiheit_Wahrheit

PROJECT_DIR="projects/Freiheit_Wahrheit"
SONG_NAME="Freiheit Wahrheit"
DURATION=$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$PROJECT_DIR/audio.mp3" 2>/dev/null)

echo "🎬 Generiere Blender-Script..."
echo "   Song: $SONG_NAME"
echo "   Dauer: $DURATION Sekunden"

# Lyrics einlesen und für Python formatieren
LYRICS_PYTHON=""
while IFS= read -r line; do
    # Überspringe Kommentare
    if [[ "$line" =~ ^#.* ]]; then
        continue
    fi
    # Escape für Python
    line="${line//\\/\\\\}"
    line="${line//\"/\\\"}"
    LYRICS_PYTHON="${LYRICS_PYTHON}    \"${line}\",\n"
done < "$PROJECT_DIR/lyrics.txt"

# Frames berechnen
FRAMES=$(printf "%.0f" $(awk "BEGIN {print $DURATION * 30}"))

# Zeilen zählen
LYRIC_COUNT=$(grep -v "^#" "$PROJECT_DIR/lyrics.txt" | wc -l)
FRAMES_PER_LYRIC=$(printf "%.0f" $(awk "BEGIN {print $FRAMES / $LYRIC_COUNT}"))

echo "   Lyrics: $LYRIC_COUNT Zeilen"
echo "   Frames: $FRAMES total, $FRAMES_PER_LYRIC pro Zeile"

# Generiere Script
sed -e "s|{{SONG_NAME}}|$SONG_NAME|g" \
    -e "s|{{DURATION_FRAMES}}|$FRAMES|g" \
    -e "s|{{LYRICS_CONTENT}}|$LYRICS_PYTHON|g" \
    -e "s|{{LYRICS_COLOR}}|(1.0, 0.757, 0.027, 1)  # Orange für Punk/Rock|g" \
    -e "s|{{FRAMES_PER_LYRIC}}|$FRAMES_PER_LYRIC|g" \
    templates/visualizer_base.py > "$PROJECT_DIR/blender_script.py"

# Kopiere auch ins Backup-Verzeichnis
BACKUP_DIR="/home/heiko/Dokumente/HTML_Webseiten/tuxhs.de/backup"
mkdir -p "$BACKUP_DIR"
cp "$PROJECT_DIR/blender_script.py" "$BACKUP_DIR/Freiheit_Wahrheit_visualizer.py"

echo "✅ Blender-Script erstellt!"
echo "   📁 $PROJECT_DIR/blender_script.py"
echo "   📁 $BACKUP_DIR/Freiheit_Wahrheit_visualizer.py"
echo ""
echo "🎬 Nächster Schritt: Blender öffnen!"
