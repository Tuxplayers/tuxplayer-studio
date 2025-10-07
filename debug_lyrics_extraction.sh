#!/bin/bash
# Debug-Script für Lyrics-Extraktion mit lyrics-transcriber

PROJECT="projects/Freiheit_Wahrheit"
AUDIO="$PROJECT/audio.mp3"
LYRICS="$PROJECT/lyrics.txt"

echo "🔍 TUXPLAYER Lyrics Debug"
echo "========================="

# Aktiviere venv
source venv/bin/activate

# 1. Prüfe Audio
echo -e "\n1️⃣ Prüfe Audio-Datei..."
if [ -f "$AUDIO" ]; then
    size=$(du -h "$AUDIO" | cut -f1)
    duration=$(ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$AUDIO" 2>/dev/null)
    echo "   ✅ Audio gefunden: $size, $(printf "%.0f" $duration)s"
else
    echo "   ❌ Audio nicht gefunden!"
    exit 1
fi

# 2. Teste lyrics-transcriber
echo -e "\n2️⃣ Teste lyrics-transcriber..."
if command -v lyrics-transcriber &> /dev/null; then
    echo "   ✅ lyrics-transcriber gefunden"
    version=$(lyrics-transcriber --version 2>&1 | head -1)
    echo "   Version: $version"
else
    echo "   ❌ lyrics-transcriber nicht gefunden"
    exit 1
fi

# 3. Prüfe existierende Lyrics-Dateien
echo -e "\n3️⃣ Prüfe existierende Lyrics-Dateien..."
echo "   Im Verzeichnis $PROJECT/:"
ls -lh "$PROJECT/"*.txt "$PROJECT/"*.lrc "$PROJECT/"*.ass 2>/dev/null | awk '{print "     " $9 " (" $5 ")"}'

has_lyrics=false
for ext in txt lrc ass; do
    if ls "$PROJECT/"*."$ext" 2>/dev/null | grep -v "lyrics.txt" > /dev/null; then
        has_lyrics=true
        break
    fi
done

# 4. Generiere Lyrics falls nötig
if [ "$has_lyrics" = false ]; then
    echo -e "\n4️⃣ Keine Lyrics gefunden - generiere jetzt..."
    echo "   ⏳ Das dauert 2-5 Minuten (Whisper AI läuft)..."
    echo ""
    echo "   Befehl:"
    echo "   lyrics-transcriber $AUDIO \\"
    echo "     --output_dir $PROJECT/ \\"
    echo "     --artist 'Heiko Schäfer' \\"
    echo "     --title 'Freiheit Wahrheit' \\"
    echo "     --skip_cdg --skip_video"
    echo ""
    read -p "   Jetzt starten? (j/n): " answer
    
    if [ "$answer" = "j" ]; then
        lyrics-transcriber "$AUDIO" \
            --output_dir "$PROJECT/" \
            --artist "Heiko Schäfer" \
            --title "Freiheit Wahrheit" \
            --skip_cdg \
            --skip_video
        
        echo ""
        echo "   ✅ Lyrics-Transkription abgeschlossen!"
    else
        echo "   Übersprungen."
    fi
else
    echo "   ✅ Lyrics-Dateien bereits vorhanden"
fi

# 5. Zeige generierte Dateien
echo -e "\n5️⃣ Generierte Dateien:"
for file in "$PROJECT"/*.{txt,lrc,ass}; do
    if [ -f "$file" ] && [ "$(basename "$file")" != "lyrics.txt" ]; then
        size=$(du -h "$file" | cut -f1)
        lines=$(wc -l < "$file" 2>/dev/null || echo "?")
        echo "   📄 $(basename "$file") - $size, $lines Zeilen"
        
        # Zeige Vorschau
        echo "      Vorschau:"
        head -5 "$file" | sed 's/^/        /'
        echo "        ..."
    fi
done

# 6. Extrahiere in lyrics.txt
echo -e "\n6️⃣ Extrahiere Lyrics für Blender..."
if python3 extract_lyrics.py "$PROJECT/"; then
    echo "   ✅ Extraktion erfolgreich!"
else
    echo "   ❌ Fehler bei Extraktion"
    exit 1
fi

# 7. Prüfe Ergebnis
echo -e "\n7️⃣ Prüfe lyrics.txt..."
if [ -f "$LYRICS" ]; then
    line_count=$(grep -v "^#" "$LYRICS" | grep -v "^$" | wc -l)
    total_lines=$(wc -l < "$LYRICS")
    
    if [ "$line_count" -gt 0 ]; then
        echo "   ✅ Lyrics gefunden: $line_count Zeilen (von $total_lines gesamt)"
        echo -e "\n   📝 Vorschau (erste 10 Zeilen):"
        grep -v "^#" "$LYRICS" | grep -v "^$" | head -10 | nl -s'. ' -w2
        
        if [ "$line_count" -gt 10 ]; then
            echo "        ... und $(($line_count - 10)) weitere Zeilen"
        fi
    else
        echo "   ⚠️  Datei existiert, aber ist leer!"
        echo "   📄 Inhalt:"
        cat "$LYRICS"
    fi
else
    echo "   ❌ lyrics.txt wurde nicht erstellt!"
fi

# 8. Zusammenfassung
echo -e "\n✅ Debug abgeschlossen!"
echo ""
echo "📋 Nächste Schritte:"
echo "   1. Editiere lyrics.txt:"
echo "      kate $LYRICS"
echo ""
echo "   2. Füge Struktur hinzu:"
echo "      [Verse 1]"
echo "      Deine Lyrics..."
echo "      "
echo "      [Chorus]"
echo "      ..."
echo ""
echo "   3. Generiere Blender-Script:"
echo "      ./improved_tuxplayer.sh"

deactivate
