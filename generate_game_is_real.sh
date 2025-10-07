#!/bin/bash
PROJECT_DIR="projects/The_Game_Is_Real"
SONG_NAME="The Game Is Real"

echo "🎬 Generiere Blender-Script für '$SONG_NAME'..."

# Song-Info
DURATION=$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$PROJECT_DIR/audio.mp3" 2>/dev/null)

DURATION_MIN=$(awk "BEGIN {printf \"%.2f\", $DURATION/60}")
echo "   🎵 Dauer: $DURATION_MIN Minuten"

# Lyrics formatieren für Python
LYRICS_PYTHON=""
while IFS= read -r line; do
    if [[ "$line" =~ ^#.* ]]; then
        continue
    fi
    line="${line//\\/\\\\}"
    line="${line//\"/\\\"}"
    LYRICS_PYTHON="${LYRICS_PYTHON}    \"${line}\",\n"
done < "$PROJECT_DIR/lyrics.txt"

# Frames berechnen
FRAMES=$(printf "%.0f" $(awk "BEGIN {print $DURATION * 30}"))
LYRIC_COUNT=$(grep -v "^#" "$PROJECT_DIR/lyrics.txt" | grep -v "^$" | wc -l)
FRAMES_PER_LYRIC=$(printf "%.0f" $(awk "BEGIN {print $FRAMES / $LYRIC_COUNT}"))

echo "   📝 Lyrics: $LYRIC_COUNT Zeilen"
echo "   ⚙️  Timing: $FRAMES_PER_LYRIC Frames/Zeile ($(awk "BEGIN {printf \"%.1f\", $FRAMES_PER_LYRIC/30}")s)"

# Generiere Script - CYAN für Electronic Style!
sed -e "s|{{SONG_NAME}}|$SONG_NAME|g" \
    -e "s|{{DURATION_FRAMES}}|$FRAMES|g" \
    -e "s|{{LYRICS_CONTENT}}|$LYRICS_PYTHON|g" \
    -e "s|{{LYRICS_COLOR}}|(0.0, 0.737, 0.831, 1)  # Cyan Electronic|g" \
    -e "s|{{FRAMES_PER_LYRIC}}|$FRAMES_PER_LYRIC|g" \
    templates/visualizer_base.py > "$PROJECT_DIR/blender_script.py"

# Backup
BACKUP_DIR="/home/heiko/Dokumente/HTML_Webseiten/tuxhs.de/backup"
mkdir -p "$BACKUP_DIR"
cp "$PROJECT_DIR/blender_script.py" "$BACKUP_DIR/The_Game_Is_Real_visualizer.py"

echo "✅ Fertig!"
echo "   📁 $PROJECT_DIR/blender_script.py"
echo "   📁 $BACKUP_DIR/The_Game_Is_Real_visualizer.py"
