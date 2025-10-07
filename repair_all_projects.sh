#!/bin/bash
# Repariert alle Projekte

cd /home/heiko/scripts/tools/lyrics-tools/

echo "🔧 REPARIERE ALLE PROJEKTE"
echo "=========================="

repaired=0

for dir in projects/*/; do
    if [ ! -d "$dir" ]; then
        continue
    fi
    
    name=$(basename "$dir")
    echo -e "\nPrüfe: $name"
    
    # Prüfe audio.mp3
    if [ ! -f "$dir/audio.mp3" ]; then
        echo "  ❌ Keine audio.mp3"
        continue
    fi
    echo "  ✅ Audio vorhanden"
    
    # Prüfe lyrics.txt
    if [ ! -f "$dir/lyrics.txt" ]; then
        echo "  ⚠️  Keine lyrics.txt - erstelle Platzhalter"
        echo "Deine Lyrics hier" > "$dir/lyrics.txt"
    fi
    
    lyric_count=$(grep -v "^#" "$dir/lyrics.txt" | grep -v "^$" | wc -l)
    echo "  ✅ Lyrics: $lyric_count Zeilen"
    
    # Prüfe blender_script.py
    if [ ! -f "$dir/blender_script.py" ]; then
        echo "  🔄 Generiere Blender-Script..."
        
        duration=$(ffprobe -v error -show_entries format=duration \
            -of default=noprint_wrappers=1:nokey=1 "$dir/audio.mp3" 2>/dev/null)
        
        if [ -n "$duration" ]; then
            ./universal_generator.sh "$name" electronic
            repaired=$((repaired + 1))
            echo "  ✅ Script generiert!"
        else
            echo "  ❌ Kann Dauer nicht ermitteln"
        fi
    else
        echo "  ✅ Blender-Script vorhanden"
    fi
done

echo -e "\n✅ Fertig! $repaired Projekt(e) repariert"
