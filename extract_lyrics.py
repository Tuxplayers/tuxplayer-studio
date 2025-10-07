#!/usr/bin/env python3
"""
TUXPLAYER Lyrics Extractor
Extrahiert Lyrics aus MP3-Dateien und bereitet sie für Blender vor
"""

import json
import sys
import os
from pathlib import Path

def extract_lyrics_from_json(json_file):
    """
    Extrahiert Lyrics aus lyrics-transcriber JSON Output
    """
    try:
        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        lyrics = []
        
        # lyrics-transcriber gibt Wort-für-Wort Timestamps
        # Wir gruppieren sie zu Zeilen basierend auf Pausen
        if 'segments' in data:
            for segment in data['segments']:
                text = segment.get('text', '').strip()
                if text:
                    lyrics.append(text)
        
        # Fallback: Wenn "text" direkt vorhanden
        elif 'text' in data:
            full_text = data['text'].strip()
            # Teile bei Satzzeichen und neuen Zeilen
            lines = full_text.replace('. ', '.\n').replace('! ', '!\n').split('\n')
            lyrics = [line.strip() for line in lines if line.strip()]
        
        return lyrics
    
    except Exception as e:
        print(f"Fehler beim Lesen der JSON: {e}")
        return []


def format_lyrics_for_blender(lyrics):
    """
    Formatiert Lyrics für Blender Python-Script
    """
    formatted = []
    for line in lyrics:
        # Escape Quotes und Backslashes
        escaped = line.replace('\\', '\\\\').replace('"', '\\"')
        formatted.append(f'    "{escaped}",')
    
    return '\n'.join(formatted)


def create_lyrics_txt(lyrics, output_file):
    """
    Erstellt eine editierbare lyrics.txt Datei
    """
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("# Bearbeite diese Lyrics nach Bedarf\n")
        f.write("# Eine Zeile = Ein Anzeige-Segment im Video\n")
        f.write("# Leere Zeilen = Pause\n\n")
        
        for i, line in enumerate(lyrics, 1):
            f.write(f"{line}\n")


def main():
    if len(sys.argv) < 2:
        print("Usage: extract_lyrics.py <timestamps.json>")
        sys.exit(1)
    
    json_file = sys.argv[1]
    
    if not os.path.exists(json_file):
        print(f"Fehler: {json_file} nicht gefunden!")
        sys.exit(1)
    
    # Extrahiere Lyrics
    print(f"📖 Extrahiere Lyrics aus {json_file}...")
    lyrics = extract_lyrics_from_json(json_file)
    
    if not lyrics:
        print("❌ Keine Lyrics gefunden!")
        sys.exit(1)
    
    print(f"✅ {len(lyrics)} Lyrics-Zeilen gefunden")
    
    # Erstelle lyrics.txt
    project_dir = Path(json_file).parent
    lyrics_file = project_dir / "lyrics.txt"
    create_lyrics_txt(lyrics, lyrics_file)
    print(f"✅ Lyrics gespeichert: {lyrics_file}")
    
    # Formatiere für Blender
    blender_format = format_lyrics_for_blender(lyrics)
    blender_file = project_dir / "lyrics_for_blender.txt"
    with open(blender_file, 'w', encoding='utf-8') as f:
        f.write(blender_format)
    print(f"✅ Blender-Format: {blender_file}")
    
    # Zeige Vorschau
    print("\n📝 Vorschau der ersten 5 Zeilen:")
    for i, line in enumerate(lyrics[:5], 1):
        print(f"  {i}. {line}")
    
    if len(lyrics) > 5:
        print(f"  ... und {len(lyrics)-5} weitere")


if __name__ == "__main__":
    main()
