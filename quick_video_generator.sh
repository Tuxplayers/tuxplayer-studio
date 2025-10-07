#!/bin/bash
# Quick Video Generator für Freiheit_Wahrheit

PROJECT="projects/Freiheit_Wahrheit"
AUDIO="$PROJECT/audio.mp3"
LYRICS="$PROJECT/lyrics.txt"
BLENDER_SCRIPT="$PROJECT/blender_script.py"
BACKUP_DIR="/home/heiko/Dokumente/HTML_Webseiten/tuxhs.de/backup"

echo "🎬 TUXPLAYER Quick Video Generator"
echo "===================================="

# 1. Prüfe Dateien
echo -e "\n1️⃣ Prüfe Projekt-Dateien..."

if [ ! -f "$AUDIO" ]; then
    echo "   ❌ Audio fehlt: $AUDIO"
    exit 1
fi
echo "   ✅ Audio vorhanden"

if [ ! -f "$LYRICS" ]; then
    echo "   ❌ Lyrics fehlen: $LYRICS"
    echo "   💡 Erstelle Lyrics-Datei manuell oder nutze lyrics-transcriber"
    exit 1
fi
echo "   ✅ Lyrics vorhanden"

# 2. Song-Info
echo -e "\n2️⃣ Song-Informationen..."
DURATION=$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$AUDIO" 2>/dev/null)
DURATION_MIN=$(awk "BEGIN {printf \"%.2f\", $DURATION/60}")
echo "   🎵 Dauer: $DURATION_MIN Minuten ($DURATION Sekunden)"

LYRIC_COUNT=$(grep -v "^#" "$LYRICS" | grep -v "^$" | wc -l)
echo "   📝 Lyrics: $LYRIC_COUNT Zeilen"

# 3. Lyrics-Vorschau
echo -e "\n3️⃣ Lyrics-Vorschau (erste 5 Zeilen):"
grep -v "^#" "$LYRICS" | grep -v "^$" | head -5 | nl -s'. ' -w2

# 4. Generiere Blender-Script
echo -e "\n4️⃣ Generiere Blender-Script..."

# Lyrics für Python formatieren
LYRICS_PYTHON=""
while IFS= read -r line; do
    # Überspringe Kommentare und leere Zeilen am Anfang
    if [[ "$line" =~ ^#.* ]]; then
        continue
    fi
    # Escape
    line="${line//\\/\\\\}"
    line="${line//\"/\\\"}"
    LYRICS_PYTHON="${LYRICS_PYTHON}    \"${line}\",\n"
done < "$LYRICS"

# Frames berechnen
FRAMES=$(printf "%.0f" $(awk "BEGIN {print $DURATION * 30}"))
FRAMES_PER_LYRIC=$(printf "%.0f" $(awk "BEGIN {print $FRAMES / $LYRIC_COUNT}"))

echo "   ⚙️  Frames total: $FRAMES"
echo "   ⚙️  Frames pro Zeile: $FRAMES_PER_LYRIC ($(awk "BEGIN {printf \"%.1f\", $FRAMES_PER_LYRIC/30}")s)"

# Template verwenden
if [ ! -f "templates/visualizer_base.py" ]; then
    echo "   ❌ Template fehlt: templates/visualizer_base.py"
    exit 1
fi

sed -e "s|{{SONG_NAME}}|Freiheit Wahrheit|g" \
    -e "s|{{DURATION_FRAMES}}|$FRAMES|g" \
    -e "s|{{LYRICS_CONTENT}}|$LYRICS_PYTHON|g" \
    -e "s|{{LYRICS_COLOR}}|(1.0, 0.757, 0.027, 1)  # Orange Punk|g" \
    -e "s|{{FRAMES_PER_LYRIC}}|$FRAMES_PER_LYRIC|g" \
    templates/visualizer_base.py > "$BLENDER_SCRIPT"

echo "   ✅ Blender-Script generiert: $BLENDER_SCRIPT"

# 5. Kopiere ins Backup
mkdir -p "$BACKUP_DIR"
cp "$BLENDER_SCRIPT" "$BACKUP_DIR/Freiheit_Wahrheit_visualizer.py"
cp "$AUDIO" "$BACKUP_DIR/Freiheit_Wahrheit_audio.mp3"
cp "$LYRICS" "$BACKUP_DIR/Freiheit_Wahrheit_lyrics.txt"

echo -e "\n5️⃣ Dateien kopiert nach:"
echo "   📁 $BACKUP_DIR/"
echo "      - Freiheit_Wahrheit_visualizer.py"
echo "      - Freiheit_Wahrheit_audio.mp3"
echo "      - Freiheit_Wahrheit_lyrics.txt"

# 6. Anleitungen
echo -e "\n✅ FERTIG! Nächste Schritte:"
echo ""
echo "🎬 In Blender:"
echo "   1. Öffne Blender"
echo "   2. Scripting Tab → Open → $BLENDER_SCRIPT"
echo "   3. Alt+P drücken (Script ausführen)"
echo "   4. Leertaste → Animation preview"
echo ""
echo "🔊 Audio hinzufügen (2 Optionen):"
echo ""
echo "   Option A - In Blender:"
echo "   1. Video Editing Tab"
echo "   2. Add → Sound → Strip"
echo "   3. Wähle: $AUDIO"
echo "   4. Render → Render Animation (Ctrl+F12)"
echo ""
echo "   Option B - Nach Rendering mit ffmpeg:"
echo "   ffmpeg -i output_video.mp4 -i $AUDIO \\"
echo "          -c:v copy -c:a aac -shortest final.mp4"
echo ""
echo "📺 Upload zu YouTube:"
echo "   - Titel: TUXPLAYER - Freiheit Wahrheit (Official Lyrics Video)"
echo "   - Tags: Electronic, Punk, Political, Freiheit, Stuttgart"
echo "   - Beschreibung: Deine Lyrics + Kontakt/Links"
echo ""
echo "🔥 Viel Erfolg mit deinem Video!"
