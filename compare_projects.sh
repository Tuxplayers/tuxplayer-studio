#!/bin/bash
echo "📊 TUXPLAYER Projekt-Vergleich"
echo "=============================="

for proj in projects/*/; do
    if [ -d "$proj" ]; then
        name=$(basename "$proj")
        echo -e "\n🎵 $name"
        
        if [ -f "$proj/audio.mp3" ]; then
            size=$(du -h "$proj/audio.mp3" | cut -f1)
            duration=$(ffprobe -v error -show_entries format=duration \
                -of default=noprint_wrappers=1:nokey=1 "$proj/audio.mp3" 2>/dev/null)
            dur_min=$(awk "BEGIN {printf \"%.2f\", $duration/60}")
            echo "   Audio: $size, $dur_min Minuten"
        fi
        
        if [ -f "$proj/lyrics.txt" ]; then
            lines=$(grep -v "^#" "$proj/lyrics.txt" | grep -v "^$" | wc -l)
            echo "   Lyrics: $lines Zeilen"
        fi
        
        if [ -f "$proj/blender_script.py" ]; then
            script_size=$(du -h "$proj/blender_script.py" | cut -f1)
            echo "   ✅ Blender-Script: $script_size"
        else
            echo "   ⚠️  Blender-Script fehlt noch"
        fi
    fi
done

echo -e "\n✅ Vergleich abgeschlossen!"
