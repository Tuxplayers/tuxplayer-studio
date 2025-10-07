#!/bin/bash
# TUXPLAYER Studio - Lyrics Video Generator
# KDE GUI Manager für Blender Musikvideos

SCRIPT_DIR="/home/heiko/scripts/tools/lyrics-tools"
VENV_DIR="$SCRIPT_DIR/venv"
PROJECTS_DIR="$SCRIPT_DIR/projects"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

mkdir -p "$PROJECTS_DIR"
mkdir -p "$TEMPLATES_DIR"

show_main_menu() {
    choice=$(kdialog --title "TUXPLAYER Studio" \
        --menu "Was möchtest du tun?" \
        1 "🎵 Neues Musikvideo erstellen" \
        2 "📂 Bestehendes Projekt öffnen" \
        3 "🔧 Timestamps für MP3 generieren" \
        4 "📋 Projekte verwalten" \
        5 "❌ Beenden")
    
    case $choice in
        1) create_new_project ;;
        2) open_existing_project ;;
        3) generate_timestamps_only ;;
        4) manage_projects ;;
        5) exit 0 ;;
        *) exit 0 ;;
    esac
}

create_new_project() {
    song_name=$(kdialog --title "Song-Name" \
        --inputbox "Wie heißt dein Song?")
    
    if [ -z "$song_name" ]; then
        kdialog --error "Kein Name eingegeben!"
        show_main_menu
        return
    fi
    
    project_dir="$PROJECTS_DIR/${song_name// /_}"
    mkdir -p "$project_dir"
    
    mp3_file=$(kdialog --title "MP3 auswählen" \
        --getopenfilename "$HOME" "*.mp3 *.MP3|MP3 Audio Files")
    
    if [ -z "$mp3_file" ]; then
        kdialog --error "Keine MP3 ausgewählt!"
        show_main_menu
        return
    fi
    
    cp "$mp3_file" "$project_dir/audio.mp3"
    
    duration=$(ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$project_dir/audio.mp3" 2>/dev/null)
    
    if [ -z "$duration" ]; then
        duration="180"
    fi
    
    lyrics_file="$project_dir/lyrics.txt"
    cat > "$lyrics_file" << 'LYRICSEOF'
[Verse 1]
Erste Zeile hier eingeben
Zweite Zeile hier eingeben
Dritte Zeile

[Chorus]
Chorus Text hier
Weitere Zeile

[Verse 2]
Vierte Zeile
Fünfte Zeile

[Bridge]
Bridge Text hier

[Final Chorus]
Letzter Chorus
LYRICSEOF
    
    xdg-open "$lyrics_file" 2>/dev/null || kate "$lyrics_file" 2>/dev/null || gedit "$lyrics_file"
    
    kdialog --msgbox "Bearbeite jetzt die Lyrics-Datei.\nErsetze den Beispiel-Text mit deinen echten Lyrics.\nEine Zeile pro Text-Segment.\n\nKlicke OK wenn fertig."
    
    style=$(kdialog --title "Visualizer-Style" \
        --menu "Welchen Style möchtest du?" \
        1 "Metal/Rock (Orange Lyrics)" \
        2 "Electronic/EDM (Cyan Lyrics)" \
        3 "Pop/Mainstream (Green Lyrics)")
    
    if kdialog --title "Timestamps" \
        --yesno "Sollen automatische Timestamps mit Whisper AI generiert werden?\n\n(Dauert je nach Song-Länge 1-5 Minuten)"; then
        
        generate_timestamps "$project_dir/audio.mp3" "$project_dir/timestamps.json"
        has_timestamps="yes"
    else
        has_timestamps="no"
    fi
    
    cat > "$project_dir/project.info" <<INFOEOF
SONG_NAME=$song_name
DURATION=$duration
STYLE=$style
HAS_TIMESTAMPS=$has_timestamps
CREATED=$(date +%Y-%m-%d)
INFOEOF
    
    generate_blender_script "$project_dir" "$song_name" "$style" "$duration" "$has_timestamps"
    
    kdialog --msgbox "✅ Projekt erstellt!\n\nPfad: $project_dir\n\nDu kannst jetzt:\n1. Blender öffnen\n2. Script laden: $project_dir/blender_script.py\n3. Alt+P drücken"
    
    if kdialog --yesno "Projekt-Ordner jetzt öffnen?"; then
        xdg-open "$project_dir"
    fi
    
    show_main_menu
}

generate_timestamps() {
    local audio_file=$1
    local output_file=$2
    
    (
        echo "0"
        echo "# Aktiviere virtuelle Umgebung..."
        cd "$SCRIPT_DIR"
        source "$VENV_DIR/bin/activate"
        
        echo "25"
        echo "# Analysiere Audio mit Whisper AI..."
        
        lyrics-transcriber "$audio_file" -o "$output_file" 2>&1 | while read line; do
            echo "# $line"
        done
        
        echo "100"
        echo "# Fertig!"
        sleep 1
    ) | kdialog --title "Timestamps generieren" \
        --progressbar "Bitte warten..." 100
    
    if [ -f "$output_file" ]; then
        kdialog --msgbox "✅ Timestamps erfolgreich generiert!\n\n$output_file"
    else
        kdialog --error "❌ Fehler beim Generieren der Timestamps!"
    fi
}

generate_timestamps_only() {
    mp3_file=$(kdialog --getopenfilename "$HOME" "*.mp3|MP3 Files")
    
    if [ -z "$mp3_file" ]; then
        show_main_menu
        return
    fi
    
    output_file="${mp3_file%.mp3}_timestamps.json"
    
    generate_timestamps "$mp3_file" "$output_file"
    
    show_main_menu
}

generate_blender_script() {
    local project_dir=$1
    local song_name=$2
    local style=$3
    local duration=$4
    local has_timestamps=$5
    
    local lyrics_python=""
    while IFS= read -r line; do
        line="${line//\"/\\\"}"
        line="${line//\\/\\\\}"
        lyrics_python="${lyrics_python}    \"${line}\",\n"
    done < "$project_dir/lyrics.txt"
    
    case $style in
        1) lyrics_color="(1.0, 0.757, 0.027, 1)  # Orange Metal" ;;
        2) lyrics_color="(0.0, 0.737, 0.831, 1)  # Cyan Electronic" ;;
        3) lyrics_color="(0.545, 0.765, 0.290, 1)  # Green Pop" ;;
        *) lyrics_color="(1.0, 0.757, 0.027, 1)" ;;
    esac
    
    frames=$(printf "%.0f" $(awk "BEGIN {print $duration * 30}"))
    frames_per_lyric=120
    
    sed -e "s|{{SONG_NAME}}|$song_name|g" \
        -e "s|{{DURATION_FRAMES}}|$frames|g" \
        -e "s|{{LYRICS_CONTENT}}|$lyrics_python|g" \
        -e "s|{{LYRICS_COLOR}}|$lyrics_color|g" \
        -e "s|{{FRAMES_PER_LYRIC}}|$frames_per_lyric|g" \
        -e "s|{{CREATED_DATE}}|$(date +%Y-%m-%d)|g" \
        "$TEMPLATES_DIR/visualizer_base.py" > "$project_dir/blender_script.py"
    
    if [ "$has_timestamps" = "yes" ]; then
        sed -e "s|{{TIMESTAMPS_FILE}}|$project_dir/timestamps.json|g" \
            -e "s|{{PROJECT_DIR}}|$project_dir|g" \
            "$TEMPLATES_DIR/timestamp_importer.py" > "$project_dir/blender_import_timestamps.py"
    fi
}

open_existing_project() {
    projects=()
    for dir in "$PROJECTS_DIR"/*/; do
        if [ -f "$dir/project.info" ]; then
            basename=$(basename "$dir")
            projects+=("$basename" "$basename")
        fi
    done
    
    if [ ${#projects[@]} -eq 0 ]; then
        kdialog --sorry "Keine Projekte gefunden!"
        show_main_menu
        return
    fi
    
    project=$(kdialog --menu "Projekt auswählen:" "${projects[@]}")
    
    if [ -n "$project" ]; then
        xdg-open "$PROJECTS_DIR/$project"
    fi
    
    show_main_menu
}

manage_projects() {
    kdialog --msgbox "Projekt-Verwaltung\n\nDeine Projekte findest du in:\n$PROJECTS_DIR"
    xdg-open "$PROJECTS_DIR"
    show_main_menu
}

check_setup() {
    if [ ! -d "$VENV_DIR" ]; then
        if kdialog --yesno "Virtuelle Umgebung nicht gefunden!\n\nJetzt erstellen und lyrics-transcriber installieren?"; then
            (
                echo "10"
                echo "# Erstelle virtuelle Umgebung..."
                python3 -m venv "$VENV_DIR"
                
                echo "30"
                echo "# Aktiviere Umgebung..."
                source "$VENV_DIR/bin/activate"
                
                echo "50"
                echo "# Installiere lyrics-transcriber..."
                pip install lyrics-transcriber
                
                echo "100"
                echo "# Fertig!"
                sleep 1
            ) | kdialog --progressbar "Setup läuft..." 100
            
            kdialog --msgbox "✅ Setup abgeschlossen!"
        else
            exit 1
        fi
    fi
}

check_setup
show_main_menu
