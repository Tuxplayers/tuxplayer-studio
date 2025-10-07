#!/bin/bash
# Systemtest für TUXPLAYER

echo "🧪 TUXPLAYER System-Check"
echo "========================="

# Check 1: venv
echo -e "\n1️⃣ Python Umgebung:"
if [ -d "venv" ]; then
    echo "   ✅ venv vorhanden"
    source venv/bin/activate
    if command -v lyrics-transcriber &> /dev/null; then
        echo "   ✅ lyrics-transcriber installiert"
    else
        echo "   ⚠️  lyrics-transcriber fehlt - installiere..."
        pip install lyrics-transcriber
    fi
    deactivate
else
    echo "   ❌ venv fehlt"
fi

# Check 2: Scripts
echo -e "\n2️⃣ Scripts:"
for script in improved_tuxplayer.sh extract_lyrics.py generate_blender_script.sh; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        echo "   ✅ $script"
    else
        echo "   ⚠️  $script (chmod +x?)"
    fi
done

# Check 3: Templates
echo -e "\n3️⃣ Templates:"
if [ -f "templates/visualizer_base.py" ]; then
    lines=$(wc -l < templates/visualizer_base.py)
    echo "   ✅ visualizer_base.py ($lines Zeilen)"
else
    echo "   ❌ visualizer_base.py fehlt!"
fi

# Check 4: Projekte
echo -e "\n4️⃣ Projekte:"
if [ -d "projects" ]; then
    count=$(ls -1 projects/ 2>/dev/null | wc -l)
    echo "   ✅ $count Projekt(e):"
    for proj in projects/*/; do
        if [ -d "$proj" ]; then
            name=$(basename "$proj")
            has_audio="❌"
            has_lyrics="❌"
            has_script="❌"
            
            [ -f "$proj/audio.mp3" ] && has_audio="✅"
            [ -f "$proj/lyrics.txt" ] && has_lyrics="✅"
            [ -f "$proj/blender_script.py" ] && has_script="✅"
            
            echo "      📁 $name: Audio:$has_audio Lyrics:$has_lyrics Script:$has_script"
        fi
    done
else
    echo "   ⚠️  Keine Projekte"
fi

# Check 5: Backup-Dir
echo -e "\n5️⃣ Backup-Verzeichnis:"
BACKUP="/home/heiko/Dokumente/HTML_Webseiten/tuxhs.de/backup"
if [ -d "$BACKUP" ]; then
    count=$(ls -1 "$BACKUP"/*visualizer.py 2>/dev/null | wc -l)
    echo "   ✅ $BACKUP ($count Scripts)"
else
    echo "   ⚠️  Backup-Dir fehlt - wird beim ersten Run erstellt"
fi

echo -e "\n✅ System-Check abgeschlossen!"
echo -e "\n🚀 Bereit! Starte mit: ./improved_tuxplayer.sh"
