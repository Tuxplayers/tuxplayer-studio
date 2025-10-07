#!/usr/bin/env python3
"""
TUXPLAYER Lyrics Extractor
Liest lyrics-transcriber Output und bereitet ihn für Blender vor
"""

import sys
import os
from pathlib import Path
import re

def extract_from_txt(txt_file):
    """Liest plain text lyrics aus .txt Datei"""
    try:
        with open(txt_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        lyrics = []
        for line in lines:
            line = line.strip()
            # Überspringe Metadaten und leere Zeilen
            if line and not line.startswith('[') and not line.startswith('#'):
                lyrics.append(line)
        
        return lyrics
    except Exception as e:
        print(f"Fehler beim Lesen von {txt_file}: {e}")
        return []

def extract_from_lrc(lrc_file):
    """Liest timed lyrics aus .lrc Datei"""
    try:
        with open(lrc_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        lyrics = []
        for line in lines:
            line = line.strip()
            # LRC Format: [mm:ss.xx]Text
            match = re.match(r'\[\d+:\d+\.\d+\](.*)', line)
            if match:
                text = match.group(1).strip()
                if text:
                    lyrics.append(text)
        
        return lyrics
    except Exception as e:
        print(f"Fehler beim Lesen von {lrc_file}: {e}")
        return []

def create_lyrics_txt(lyrics, output_file):
    """Erstellt eine editierbare lyrics.txt Datei"""
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("# TUXPLAYER Lyrics\n")
        f.write("# Bearbeite diese Lyrics nach Bedarf\n")
        f.write("# Eine Zeile = Ein Anzeige-Segment im Video\n")
        f.write("# Leere Zeilen = Pause\n")
        f.write("# Du kannst [Verse], [Chorus] etc. hinzufügen\n\n")
        
        for line in lyrics:
            f.write(f"{line}\n")

def find_lyrics_files(directory):
    """Findet generierte Lyrics-Dateien im Verzeichnis"""
    dir_path = Path(directory)
    
    # Suche nach .txt und .lrc Dateien (aber nicht unsere eigene lyrics.txt)
    txt_files = [f for f in dir_path.glob("*.txt") if f.name != "lyrics.txt"]
    lrc_files = list(dir_path.glob("*.lrc"))
    
    return txt_files, lrc_files

def main():
    if len(sys.argv) < 2:
        print("Usage: extract_lyrics.py <project_directory>")
        print("Beispiel: extract_lyrics.py projects/Freiheit_Wahrheit/")
        sys.exit(1)
    
    project_dir = sys.argv[1]
    
    if not os.path.exists(project_dir):
        print(f"Fehler: {project_dir} nicht gefunden!")
        sys.exit(1)
    
    print(f"🔍 Suche Lyrics in {project_dir}...")
    
    txt_files, lrc_files = find_lyrics_files(project_dir)
    
    print(f"📄 Gefunden:")
    print(f"   TXT Dateien: {len(txt_files)}")
    for f in txt_files:
        print(f"     - {f.name}")
    print(f"   LRC Dateien: {len(lrc_files)}")
    for f in lrc_files:
        print(f"     - {f.name}")
    
    lyrics = []
    
    # Versuche zuerst .txt
    if txt_files:
        print(f"\n📖 Lese aus {txt_files[0].name}...")
        lyrics = extract_from_txt(txt_files[0])
    
    # Fallback: .lrc
    if not lyrics and lrc_files:
        print(f"\n📖 Lese aus {lrc_files[0].name}...")
        lyrics = extract_from_lrc(lrc_files[0])
    
    if not lyrics:
        print("❌ Keine Lyrics gefunden!")
        print("\n💡 Tipp: Führe zuerst aus:")
        print(f"   lyrics-transcriber <audio.mp3> --output_dir {project_dir}")
        sys.exit(1)
    
    print(f"✅ {len(lyrics)} Lyrics-Zeilen gefunden")
    
    # Erstelle lyrics.txt
    lyrics_file = Path(project_dir) / "lyrics.txt"
    create_lyrics_txt(lyrics, lyrics_file)
    print(f"✅ Lyrics gespeichert: {lyrics_file}")
    
    # Zeige Vorschau
    print("\n📝 Vorschau (erste 10 Zeilen):")
    for i, line in enumerate(lyrics[:10], 1):
        print(f"  {i:2d}. {line}")
    
    if len(lyrics) > 10:
        print(f"  ... und {len(lyrics)-10} weitere Zeilen")
    
    print("\n✏️  Editiere jetzt die Lyrics:")
    print(f"   kate {lyrics_file}")
    print(f"   oder: gedit {lyrics_file}")

if __name__ == "__main__":
    main()
