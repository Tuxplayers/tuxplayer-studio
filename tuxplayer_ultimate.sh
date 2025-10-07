#!/bin/bash
# TUXPLAYER Studio - Perfekte GUI mit direkter Texteingabe
# Version 3.0 - Mit Multi-Line Input Dialog

SCRIPT_DIR="/home/heiko/scripts/tools/lyrics-tools"
PROJECTS_DIR="$SCRIPT_DIR/projects"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
BLENDER_OUTPUT="/home/heiko/Dokumente/HTML_Webseiten/tuxhs.de/backup"

# Bereinige Song-Namen
sanitize_name() {
    local name="$1"
    name="${name//[/}"; name="${name//]/}"
    name="${name//(/}"; name="${name//)/}"
    name="${name//\"/}"; name="${name//\'/}"
    name="${name//\?/}"; name="${name//!/}"
    name="${name//:/}"; name="${name//;/}"
    name="${name//,/}"; name="${name//\*/}"
    name="${name//|/}"; name="${name//<}/}"
    name="${name//>}/}"; name="${name//\&/and}"
    name="${name// /_}"
    name="${name//__/_}"
    name="${name/#_/}"; name="${name/%_/}"
    echo "$name"
}

show_main_menu() {
    choice=$(kdialog --title "🎵 TUXPLAYER Studio" \
        --menu "Was möchtest du tun?" \
        1 "🎬 Neues Musikvideo erstellen" \
        2 "📂 Bestehendes Projekt bearbeiten" \
        3 "📊 Alle Projekte anzeigen" \
        4 "❌ Beenden")
    
    case $choice in
        1) create_new_project ;;
        2) edit_existing_project ;;
        3) show_all_projects ;;
        4) exit 0 ;;
        *) exit 0 ;;
    esac
}

create_new_project() {
    # Song-Name
    song_name=$(kdialog --title "Song-Name" \
        --inputbox "Wie heißt dein Song?\n\n(Sonderzeichen werden automatisch entfernt)")
    
    if [ -z "$song_name" ]; then
        show_main_menu
        return
    fi
    
    clean_name=$(sanitize_name "$song_name")
    
    if [ "$song_name" != "$clean_name" ]; then
        kdialog --msgbox "📝 Song-Name bereinigt:\n\nOriginal: $song_name\nOrdner: $clean_name"
    fi
    
    project_dir="$PROJECTS_DIR/$clean_name"
    
    if [ -d "$project_dir" ]; then
        if ! kdialog --yesno "⚠️ Projekt '$clean_name' existiert!\n\nÜberschreiben?"; then
            show_main_menu
            return
        fi
    fi
    
    mkdir -p "$project_dir"
    
    # MP3 auswählen
    mp3_file=$(kdialog --title "MP3 auswählen" \
        --getopenfilename "$HOME" "*.mp3 *.MP3|MP3 Audio Files")
    
    if [ -z "$mp3_file" ]; then
        kdialog --error "Keine MP3 ausgewählt!"
        show_main_menu
        return
    fi
    
    cp "$mp3_file" "$project_dir/audio.mp3"
    
    # Dauer ermitteln
    duration=$(ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$project_dir/audio.mp3" 2>/dev/null)
    
    if [ -z "$duration" ]; then
        duration="180"
    fi
    
    # Style wählen
    style=$(kdialog --title "Style" \
        --menu "Welchen Style?" \
        1 "🔥 Metal/Rock (Orange)" \
        2 "💎 Electronic/EDM (Cyan)" \
        3 "🌿 Pop/Mainstream (Grün)")
    
    if [ -z "$style" ]; then
        style=2
    fi
    
    # LYRICS EINGABE - 3 Methoden
    lyrics_method=$(kdialog --title "Lyrics eingeben" \
        --menu "Wie möchtest du deine Lyrics eingeben?" \
        1 "⌨️  DIREKT HIER EINGEBEN (Empfohlen!)" \
        2 "📝 In externem Editor (Kate/Gedit)" \
        3 "📋 Aus Datei laden")
    
    case $lyrics_method in
        1)
            # DIREKT EINGABE - Multi-Line Dialog
            temp_file=$(mktemp)
            
            # Erstelle Vorlage
            cat > "$temp_file" << 'VORLAGE'
[Verse 1]
Erste Zeile
Zweite Zeile
Dritte Zeile

[Chorus]
Chorus Text
Weitere Zeile

[Verse 2]
Vierte Zeile
Fünfte Zeile
VORLAGE
            
            # Zeige Info-Dialog
            kdialog --msgbox "✍️ LYRICS DIREKT EINGEBEN\n\nIm nächsten Fenster kannst du deine Lyrics eingeben.\n\nFormat:\n[Verse 1]\nDeine Zeilen...\n\n[Chorus]\nWeitere Zeilen...\n\nTipps:\n• Eine Zeile = Ein Display-Segment\n• Leere Zeilen = Pausen\n• [Verse], [Chorus] = Struktur"
            
            # Öffne Multi-Line Input
            lyrics_text=$(kdialog --title "Lyrics eingeben" \
                --textinputbox "Gib deine Lyrics ein:\n(Mehrere Zeilen möglich)" \
                "$(cat $temp_file)" 500 400)
            
            if [ -z "$lyrics_text" ]; then
                kdialog --sorry "Keine Lyrics eingegeben!"
                rm "$temp_file"
                show_main_menu
                return
            fi
            
            # Speichere Lyrics
            echo "$lyrics_text" > "$project_dir/lyrics.txt"
            rm "$temp_file"
            ;;
        2)
            # Externer Editor
            temp_file=$(mktemp)
            cat > "$temp_file" << 'VORLAGE'
[Verse 1]
Erste Zeile
Zweite Zeile

[Chorus]
Chorus Text
VORLAGE
            
            if command -v kate &> /dev/null; then
                kate "$temp_file"
            elif command -v gedit &> /dev/null; then
                gedit "$temp_file"
            else
                kdialog --error "Kein Editor gefunden!"
                show_main_menu
                return
            fi
            
            kdialog --msgbox "Klicke OK wenn du fertig bist..."
            cp "$temp_file" "$project_dir/lyrics.txt"
            rm "$temp_file"
            ;;
        3)
            # Aus Datei laden
            lyrics_file=$(kdialog --getopenfilename "$HOME" "*.txt|Text Files")
            if [ -n "$lyrics_file" ]; then
                cp "$lyrics_file" "$project_dir/lyrics.txt"
            else
                kdialog --error "Keine Datei ausgewählt!"
                show_main_menu
                return
            fi
            ;;
        *)
            show_main_menu
            return
            ;;
    esac
    
    # Prüfe Lyrics
    if [ ! -f "$project_dir/lyrics.txt" ]; then
        kdialog --error "Keine Lyrics-Datei erstellt!"
        show_main_menu
        return
    fi
    
    lyric_count=$(grep -v "^#" "$project_dir/lyrics.txt" | grep -v "^$" | wc -l)
    
    if [ "$lyric_count" -lt 3 ]; then
        kdialog --yesno "⚠️ Nur $lyric_count Lyrics-Zeilen!\n\nMöchtest du mehr hinzufügen?"
        if [ $? -eq 0 ]; then
            kate "$project_dir/lyrics.txt" 2>/dev/null || gedit "$project_dir/lyrics.txt" 2>/dev/null
            kdialog --msgbox "Klicke OK wenn fertig..."
            lyric_count=$(grep -v "^#" "$project_dir/lyrics.txt" | grep -v "^$" | wc -l)
        fi
    fi
    
    # Generiere Blender-Script
    generate_blender_script "$project_dir" "$song_name" "$style" "$duration"
    
    # Projekt-Info
    cat > "$project_dir/project.info" <<INFO
SONG_NAME=$song_name
CLEAN_NAME=$clean_name
DURATION=$duration
STYLE=$style
LYRIC_COUNT=$lyric_count
CREATED=$(date +%Y-%m-%d_%H:%M:%S)
INFO
    
    # Erfolg!
    duration_min=$(LC_NUMERIC=C awk "BEGIN {printf \"%.2f\", $duration/60}")
    
    kdialog --msgbox "✅ PROJEKT ERSTELLT!\n\nName: $clean_name\nLyrics: $lyric_count Zeilen\nDauer: $duration_min Minuten\n\n📁 $project_dir/\n🎬 $project_dir/blender_script.py"
    
    # Was jetzt?
    action=$(kdialog --menu "Was möchtest du jetzt tun?" \
        1 "📁 Projekt-Ordner öffnen" \
        2 "📝 Lyrics nochmal bearbeiten" \
        3 "🎬 In Blender öffnen" \
        4 "↩️  Zurück zum Menü")
    
    case $action in
        1) xdg-open "$project_dir" ;;
        2) 
            kate "$project_dir/lyrics.txt" 2>/dev/null || gedit "$project_dir/lyrics.txt"
            generate_blender_script "$project_dir" "$song_name" "$style" "$duration"
            kdialog --msgbox "✅ Script neu generiert!"
            ;;
        3) blender & ;;
    esac
    
    show_main_menu
}

edit_existing_project() {
    projects=()
    for dir in "$PROJECTS_DIR"/*/; do
        if [ -d "$dir" ]; then
            name=$(basename "$dir")
            # Zeige nur gültige Projekte mit audio.mp3
            if [ -f "$dir/audio.mp3" ]; then
                projects+=("$name" "$name")
            fi
        fi
    done
    
    if [ ${#projects[@]} -eq 0 ]; then
        kdialog --sorry "Keine Projekte gefunden!"
        show_main_menu
        return
    fi
    
    project=$(kdialog --menu "Projekt auswählen:" "${projects[@]}")
    
    if [ -z "$project" ]; then
        show_main_menu
        return
    fi
    
    project_dir="$PROJECTS_DIR/$project"
    
    # Lade Projekt-Info
    if [ -f "$project_dir/project.info" ]; then
        source "$project_dir/project.info"
    else
        SONG_NAME="$project"
        STYLE=2
    fi
    
    # Was tun?
    action=$(kdialog --menu "Was möchtest du mit '$project' tun?" \
        1 "📝 Lyrics bearbeiten" \
        2 "🔄 Blender-Script neu generieren" \
        3 "📁 Ordner öffnen" \
        4 "🎬 In Blender öffnen" \
        5 "🗑️  Projekt löschen" \
        6 "↩️  Zurück")
    
    case $action in
        1)
            if [ ! -f "$project_dir/lyrics.txt" ]; then
                cat > "$project_dir/lyrics.txt" << 'VORLAGE'
[Verse 1]
Deine Lyrics hier

[Chorus]
Chorus Text hier
VORLAGE
            fi
            
            kate "$project_dir/lyrics.txt" 2>/dev/null || gedit "$project_dir/lyrics.txt"
            kdialog --msgbox "Lyrics gespeichert!"
            
            # Neu generieren?
            if kdialog --yesno "Blender-Script neu generieren?"; then
                duration=$(ffprobe -v error -show_entries format=duration \
                    -of default=noprint_wrappers=1:nokey=1 "$project_dir/audio.mp3" 2>/dev/null)
                generate_blender_script "$project_dir" "${SONG_NAME:-$project}" "${STYLE:-2}" "$duration"
                kdialog --msgbox "✅ Script neu generiert!"
            fi
            ;;
        2)
            duration=$(ffprobe -v error -show_entries format=duration \
                -of default=noprint_wrappers=1:nokey=1 "$project_dir/audio.mp3" 2>/dev/null)
            generate_blender_script "$project_dir" "${SONG_NAME:-$project}" "${STYLE:-2}" "$duration"
            kdialog --msgbox "✅ Blender-Script neu generiert!"
            ;;
        3)
            xdg-open "$project_dir"
            ;;
        4)
            blender "$project_dir/blender_script.py" &
            ;;
        5)
            if kdialog --warningyesno "⚠️ PROJEKT LÖSCHEN?\n\n'$project' wird komplett gelöscht!\n\nSicher?"; then
                rm -rf "$project_dir"
                kdialog --msgbox "🗑️ Projekt '$project' gelöscht!"
            fi
            ;;
    esac
    
    show_main_menu
}

show_all_projects() {
    info="📊 ALLE TUXPLAYER PROJEKTE\n"
    info+="="$(printf '%.0s=' {1..40})"\n\n"
    
    for dir in "$PROJECTS_DIR"/*/; do
        if [ -d "$dir" ] && [ -f "$dir/audio.mp3" ]; then
            name=$(basename "$dir")
            size=$(du -h "$dir/audio.mp3" 2>/dev/null | cut -f1)
            duration=$(ffprobe -v error -show_entries format=duration \
                -of default=noprint_wrappers=1:nokey=1 "$dir/audio.mp3" 2>/dev/null)
            dur_min=$(LC_NUMERIC=C awk "BEGIN {printf \"%.2f\", $duration/60}" 2>/dev/null)
            
            lyric_count=0
            if [ -f "$dir/lyrics.txt" ]; then
                lyric_count=$(grep -v "^#" "$dir/lyrics.txt" | grep -v "^$" | wc -l)
            fi
            
            script_status="❌"
            if [ -f "$dir/blender_script.py" ]; then
                script_status="✅"
            fi
            
            info+="🎵 $name\n"
            info+="   Audio: $size, $dur_min Min\n"
            info+="   Lyrics: $lyric_count Zeilen\n"
            info+="   Script: $script_status\n\n"
        fi
    done
    
    kdialog --msgbox "$info"
    show_main_menu
}

generate_blender_script() {
    local project_dir=$1
    local song_name=$2
    local style=$3
    local duration=$4
    
    # Lyrics einlesen
    local lyrics_python=""
    while IFS= read -r line; do
        [[ "$line" =~ ^#.* ]] && continue
        [[ -z "$line" ]] && continue
        line="${line//\\/\\\\}"
        line="${line//\"/\\\"}"
        lyrics_python="${lyrics_python}    \"${line}\",\n"
    done < "$project_dir/lyrics.txt"
    
    # Style-Farbe
    case $style in
        1) lyrics_color="(1.0, 0.757, 0.027, 1)  # Orange Metal" ;;
        2) lyrics_color="(0.0, 0.737, 0.831, 1)  # Cyan Electronic" ;;
        3) lyrics_color="(0.545, 0.765, 0.290, 1)  # Green Pop" ;;
        *) lyrics_color="(0.0, 0.737, 0.831, 1)" ;;
    esac
    
    # Frames berechnen (mit LC_NUMERIC=C für Locale-Fix)
    local frames=$(LC_NUMERIC=C printf "%.0f" $(LC_NUMERIC=C awk "BEGIN {print $duration * 30}"))
    local lyric_count=$(grep -v "^#" "$project_dir/lyrics.txt" | grep -v "^$" | wc -l)
    local frames_per_lyric=$(LC_NUMERIC=C printf "%.0f" $(LC_NUMERIC=C awk "BEGIN {print $frames / $lyric_count}"))
    
    # Generiere Script
    sed -e "s|{{SONG_NAME}}|$song_name|g" \
        -e "s|{{DURATION_FRAMES}}|$frames|g" \
        -e "s|{{LYRICS_CONTENT}}|$lyrics_python|g" \
        -e "s|{{LYRICS_COLOR}}|$lyrics_color|g" \
        -e "s|{{FRAMES_PER_LYRIC}}|$frames_per_lyric|g" \
        "$TEMPLATES_DIR/visualizer_base.py" > "$project_dir/blender_script.py"
    
    # Backup
    mkdir -p "$BLENDER_OUTPUT"
    local clean_name=$(sanitize_name "$song_name")
    cp "$project_dir/blender_script.py" "$BLENDER_OUTPUT/${clean_name}_visualizer.py"
}

# Check Setup
if [ ! -f "$TEMPLATES_DIR/visualizer_base.py" ]; then
    kdialog --error "Template fehlt!\n\n$TEMPLATES_DIR/visualizer_base.py"
    exit 1
fi

# Start
show_main_menu
