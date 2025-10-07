#!/bin/bash
# Universal Blender Script Generator
# Nutzt vorhandene lyrics.txt und audio.mp3

if [ -z "$1" ]; then
    echo "Usage: $0 <project_name> [style]"
    echo ""
    echo "Beispiel:"
    echo "  $0 The_Game_Is_Real electronic"
    echo "  $0 Freiheit_Wahrheit punk"
    echo ""
    echo "Styles: electronic (cyan), punk (orange), pop (green)"
    exit 1
fi

PROJECT_NAME="$1"
STYLE="${2:-electronic}"
PROJECT_DIR="projects/$PROJECT_NAME"

echo "🎬 TUXPLAYER Universal Generator"
echo "================================="

# Prüfe Projekt
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Projekt nicht gefunden: $PROJECT_DIR"
    exit 1
fi

echo "✅ Projekt: $PROJECT_NAME"

# Prüfe Audio
if [ ! -f "$PROJECT_DIR/audio.mp3" ]; then
    echo "❌ Audio fehlt: $PROJECT_DIR/audio.mp3"
    exit 1
fi

DURATION=$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$PROJECT_DIR/audio.mp3" 2>/dev/null)
DURATION_MIN=$(LC_NUMERIC=C awk "BEGIN {printf \"%.2f\", $DURATION/60}")
echo "✅ Audio: $DURATION_MIN Minuten"

# Prüfe Lyrics
if [ ! -f "$PROJECT_DIR/lyrics.txt" ]; then
    echo "❌ Lyrics fehlen: $PROJECT_DIR/lyrics.txt"
    exit 1
fi

LYRIC_COUNT=$(grep -v "^#" "$PROJECT_DIR/lyrics.txt" | grep -v "^$" | wc -l)

if [ "$LYRIC_COUNT" -lt 3 ]; then
    echo "❌ Zu wenige Lyrics: $LYRIC_COUNT Zeilen"
    echo "Bitte fülle $PROJECT_DIR/lyrics.txt"
    exit 1
fi

echo "✅ Lyrics: $LYRIC_COUNT Zeilen"

# Style-Farbe wählen
case $STYLE in
    electronic|cyan)
        COLOR="(0.0, 0.737, 0.831, 1)  # Cyan Electronic"
        echo "🎨 Style: Electronic (Cyan)"
        ;;
    punk|rock|orange)
        COLOR="(1.0, 0.757, 0.027, 1)  # Orange Punk"
        echo "🎨 Style: Punk/Rock (Orange)"
        ;;
    pop|green)
        COLOR="(0.545, 0.765, 0.290, 1)  # Green Pop"
        echo "🎨 Style: Pop (Green)"
        ;;
    *)
        echo "⚠️ Unbekannter Style '$STYLE', nutze Electronic"
        COLOR="(0.0, 0.737, 0.831, 1)  # Cyan Electronic"
        ;;
esac

# Lyrics für Python formatieren
LYRICS_PYTHON=""
while IFS= read -r line; do
    # Überspringe Kommentare
    if [[ "$line" =~ ^#.* ]]; then
        continue
    fi
    # Escape
    line="${line//\\/\\\\}"
    line="${line//\"/\\\"}"
    LYRICS_PYTHON="${LYRICS_PYTHON}    \"${line}\",\n"
done < "$PROJECT_DIR/lyrics.txt"

# Frames berechnen
FRAMES=$(LC_NUMERIC=C printf "%.0f" $(LC_NUMERIC=C awk "BEGIN {print $DURATION * 30}"))
FRAMES_PER_LYRIC=$(LC_NUMERIC=C printf "%.0f" $(LC_NUMERIC=C awk "BEGIN {print $FRAMES / $LYRIC_COUNT}"))
SECONDS_PER_LYRIC=$(LC_NUMERIC=C awk "BEGIN {printf \"%.1f\", $FRAMES_PER_LYRIC/30}")

echo "⚙️  Timing: $FRAMES_PER_LYRIC Frames/Zeile ($SECONDS_PER_LYRIC Sekunden)"

# Generiere Blender-Script
if [ ! -f "templates/visualizer_base.py" ]; then
    echo "❌ Template fehlt: templates/visualizer_base.py"
    exit 1
fi

# Song-Name formatieren (Unterstriche zu Leerzeichen)
DISPLAY_NAME="${PROJECT_NAME//_/ }"

sed -e "s|{{SONG_NAME}}|$DISPLAY_NAME|g" \
    -e "s|{{DURATION_FRAMES}}|$FRAMES|g" \
    -e "s|{{LYRICS_CONTENT}}|$LYRICS_PYTHON|g" \
    -e "s|{{LYRICS_COLOR}}|$COLOR|g" \
    -e "s|{{FRAMES_PER_LYRIC}}|$FRAMES_PER_LYRIC|g" \
    templates/visualizer_base.py > "$PROJECT_DIR/blender_script.py"

echo "✅ Blender-Script: $PROJECT_DIR/blender_script.py"

# Backup
BACKUP_DIR="/home/heiko/Dokumente/HTML_Webseiten/tuxhs.de/backup"
mkdir -p "$BACKUP_DIR"
cp "$PROJECT_DIR/blender_script.py" "$BACKUP_DIR/${PROJECT_NAME}_visualizer.py"
echo "✅ Backup: $BACKUP_DIR/${PROJECT_NAME}_visualizer.py"

# Info speichern
cat > "$PROJECT_DIR/project.info" <<INFOEOF
SONG_NAME=$DISPLAY_NAME
PROJECT_NAME=$PROJECT_NAME
DURATION=$DURATION
STYLE=$STYLE
LYRIC_COUNT=$LYRIC_COUNT
GENERATED=$(date +%Y-%m-%d_%H:%M:%S)
INFOEOF

echo ""
echo "🎬 Fertig! Nächste Schritte:"
echo "   1. Öffne Blender"
echo "   2. Scripting Tab → Open → $PROJECT_DIR/blender_script.py"
echo "   3. Alt+P drücken"
echo "   4. Render Animation (Ctrl+F12)"
echo ""
echo "📊 Projekt-Info:"
echo "   Song: $DISPLAY_NAME"
echo "   Dauer: $DURATION_MIN Min"
echo "   Lyrics: $LYRIC_COUNT Zeilen"
echo "   Timing: $SECONDS_PER_LYRIC Sek/Zeile"
