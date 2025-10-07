#!/bin/bash
# TUXPLAYER Studio - Finale Version
# Mit Qualitätsauswahl & automatischer Strukturfilterung

SCRIPT_DIR="/home/heiko/scripts/tools/lyrics-tools"
PROJECTS_DIR="$SCRIPT_DIR/projects"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
BLENDER_OUTPUT="/home/heiko/Dokumente/HTML_Webseiten/tuxhs.de/backup"
MP3_SOURCE="$SCRIPT_DIR/mp3_source"

sanitize_name() {
    local name="$1"
    name="${name//[^a-zA-Z0-9_]/_}"
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
        4 "🧹 Aufräumen & Reparieren" \
        5 "❌ Beenden")
    
    case $choice in
        1) create_new_project ;;
        2) edit_existing_project ;;
        3) show_all_projects ;;
        4) cleanup_and_repair ;;
        5) exit 0 ;;
        *) exit 0 ;;
    esac
}

create_new_project() {
    # Song-Name
    song_name=$(kdialog --inputbox "Song-Name:")
    [ -z "$song_name" ] && show_main_menu && return
    
    clean_name=$(sanitize_name "$song_name")
    project_dir="$PROJECTS_DIR/$clean_name"
    mkdir -p "$project_dir"
    
    # MP3 auswählen (zeige auch mp3_source Ordner)
    mp3_file=$(kdialog --getopenfilename "$MP3_SOURCE" "*.mp3|MP3 Files")
    [ -z "$mp3_file" ] && show_main_menu && return
    
    cp "$mp3_file" "$project_dir/audio.mp3"
    
    # Dauer
    duration=$(ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$project_dir/audio.mp3" 2>/dev/null)
    [ -z "$duration" ] && duration="180"
    
    # Style
    style=$(kdialog --menu "Style?" \
        1 "🔥 Metal/Rock (Orange)" \
        2 "💎 Electronic (Cyan)" \
        3 "🌿 Pop (Grün)")
    [ -z "$style" ] && style=2
    
    # QUALITÄT wählen (NEU!)
    quality=$(kdialog --menu "Video-Qualität?" \
        1 "⚡ Schnell (Standard, 64 Samples)" \
        2 "✨ Gut (Empfohlen, 128 Samples)" \
        3 "💎 Beste (256 Samples, langsam)" \
        4 "🎬 4K Ultra (3840x2160, sehr langsam)")
    [ -z "$quality" ] && quality=2
    
    # Lyrics-Eingabe
    lyrics_method=$(kdialog --menu "Lyrics eingeben?" \
        1 "⌨️  Direkt hier eingeben" \
        2 "📝 In Editor (Kate)" \
        3 "📋 Aus Datei laden")
    
    case $lyrics_method in
        1)
            lyrics_text=$(kdialog --textinputbox "Lyrics:" "" 500 400)
            [ -z "$lyrics_text" ] && show_main_menu && return
            echo "$lyrics_text" > "$project_dir/lyrics.txt"
            ;;
        2)
            echo "[Verse 1]
Deine Lyrics hier

[Chorus]
Chorus Text" > "$project_dir/lyrics.txt"
            kate "$project_dir/lyrics.txt"
            kdialog --msgbox "Klicke OK wenn fertig..."
            ;;
        3)
            lyrics_file=$(kdialog --getopenfilename "$HOME" "*.txt")
            [ -n "$lyrics_file" ] && cp "$lyrics_file" "$project_dir/lyrics.txt"
            ;;
    esac
    
    # [Verse], [Chorus] entfernen?
    if kdialog --yesno "Struktur-Markierungen [Verse], [Chorus] etc. NICHT im Video anzeigen?"; then
        grep -v '^\[.*\]$' "$project_dir/lyrics.txt" | grep -v '^$' > "$project_dir/lyrics_filtered.txt"
        mv "$project_dir/lyrics_filtered.txt" "$project_dir/lyrics.txt"
    fi
    
    # Generiere mit Qualitäts-Einstellungen
    generate_blender_script "$project_dir" "$song_name" "$style" "$duration" "$quality"
    
    # Projekt-Info
    cat > "$project_dir/project.info" <<INFO
SONG_NAME=$song_name
STYLE=$style
QUALITY=$quality
DURATION=$duration
CREATED=$(date +%Y-%m-%d)
INFO
    
    kdialog --msgbox "✅ PROJEKT ERSTELLT!\n\n$clean_name\n\n📁 $project_dir/\n🎬 Blender-Script bereit!"
    show_main_menu
}

generate_blender_script() {
    local project_dir=$1
    local song_name=$2
    local style=$3
    local duration=$4
    local quality=${5:-2}
    
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
        1) lyrics_color="(1.0, 0.757, 0.027, 1)  # Orange" ;;
        2) lyrics_color="(0.0, 0.737, 0.831, 1)  # Cyan" ;;
        3) lyrics_color="(0.545, 0.765, 0.290, 1)  # Green" ;;
        *) lyrics_color="(0.0, 0.737, 0.831, 1)" ;;
    esac
    
    # Qualitäts-Einstellungen
    local quality_boost=""
    case $quality in
        1) # Schnell
            quality_boost="
# Schnelle Qualität (Standard)
bpy.context.scene.eevee.taa_render_samples = 64
bpy.context.scene.render.ffmpeg.constant_rate_factor = 'MEDIUM'"
            ;;
        2) # Gut (Empfohlen)
            quality_boost="
# Gute Qualität (Empfohlen für YouTube)
bpy.context.scene.eevee.taa_render_samples = 128
bpy.context.scene.eevee.use_bloom = True
bpy.context.scene.eevee.bloom_intensity = 0.5
bpy.context.scene.render.ffmpeg.constant_rate_factor = 'HIGH'"
            ;;
        3) # Beste
            quality_boost="
# Beste Qualität
bpy.context.scene.eevee.taa_render_samples = 256
bpy.context.scene.eevee.use_bloom = True
bpy.context.scene.eevee.bloom_intensity = 0.5
bpy.context.scene.eevee.use_ssr = True
bpy.context.scene.render.ffmpeg.constant_rate_factor = 'PERC_LOSSLESS'"
            ;;
        4) # 4K Ultra
            quality_boost="
# 4K Ultra Qualität
bpy.context.scene.render.resolution_x = 3840
bpy.context.scene.render.resolution_y = 2160
bpy.context.scene.eevee.taa_render_samples = 256
bpy.context.scene.eevee.use_bloom = True
bpy.context.scene.eevee.bloom_intensity = 0.5
bpy.context.scene.eevee.use_ssr = True
bpy.context.scene.render.ffmpeg.constant_rate_factor = 'PERC_LOSSLESS'"
            ;;
    esac
    
    # Frames berechnen
    export LC_NUMERIC=C
    local frames=$(printf "%.0f" $(awk "BEGIN {print $duration * 30}"))
    local lyric_count=$(grep -v "^#" "$project_dir/lyrics.txt" | grep -v "^$" | wc -l)
    local frames_per_lyric=$(printf "%.0f" $(awk "BEGIN {print $frames / $lyric_count}"))
    
    # Template laden und anpassen
    sed -e "s|{{SONG_NAME}}|$song_name|g" \
        -e "s|{{DURATION_FRAMES}}|$frames|g" \
        -e "s|{{LYRICS_CONTENT}}|$lyrics_python|g" \
        -e "s|{{LYRICS_COLOR}}|$lyrics_color|g" \
        -e "s|{{FRAMES_PER_LYRIC}}|$frames_per_lyric|g" \
        "$TEMPLATES_DIR/visualizer_base.py" > "$project_dir/blender_script.py"
    
    # Qualitäts-Boost hinzufügen
    echo "$quality_boost" >> "$project_dir/blender_script.py"
    echo "print('✨ Qualität: Level $quality')" >> "$project_dir/blender_script.py"
    
    # Backup
    mkdir -p "$BLENDER_OUTPUT"
    cp "$project_dir/blender_script.py" "$BLENDER_OUTPUT/${clean_name}_visualizer.py"
}

edit_existing_project() {
    projects=()
    for dir in "$PROJECTS_DIR"/*/; do
        [ -f "$dir/audio.mp3" ] && projects+=("$(basename "$dir")" "$(basename "$dir")")
    done
    
    [ ${#projects[@]} -eq 0 ] && kdialog --sorry "Keine Projekte!" && show_main_menu && return
    
    project=$(kdialog --menu "Projekt:" "${projects[@]}")
    [ -z "$project" ] && show_main_menu && return
    
    project_dir="$PROJECTS_DIR/$project"
    
    action=$(kdialog --menu "Was tun mit '$project'?" \
        1 "📝 Lyrics bearbeiten" \
        2 "🔄 Script neu generieren" \
        3 "📁 Ordner öffnen" \
        4 "🎬 In Blender öffnen")
    
    case $action in
        1)
            kate "$project_dir/lyrics.txt"
            if kdialog --yesno "Script neu generieren?"; then
                [ -f "$project_dir/project.info" ] && source "$project_dir/project.info"
                duration=$(ffprobe -v error -show_entries format=duration \
                    -of default=noprint_wrappers=1:nokey=1 "$project_dir/audio.mp3" 2>/dev/null)
                generate_blender_script "$project_dir" "${SONG_NAME:-$project}" "${STYLE:-2}" "$duration" "${QUALITY:-2}"
                kdialog --msgbox "✅ Script neu generiert!"
            fi
            ;;
        2)
            duration=$(ffprobe -v error -show_entries format=duration \
                -of default=noprint_wrappers=1:nokey=1 "$project_dir/audio.mp3" 2>/dev/null)
            [ -f "$project_dir/project.info" ] && source "$project_dir/project.info"
            generate_blender_script "$project_dir" "${SONG_NAME:-$project}" "${STYLE:-2}" "$duration" "${QUALITY:-2}"
            kdialog --msgbox "✅ Neu generiert!"
            ;;
        3) xdg-open "$project_dir" ;;
        4) blender "$project_dir/blender_script.py" & ;;
    esac
    
    show_main_menu
}

show_all_projects() {
    info="📊 ALLE PROJEKTE\n═══════════════\n\n"
    
    for dir in "$PROJECTS_DIR"/*/; do
        if [ -f "$dir/audio.mp3" ]; then
            name=$(basename "$dir")
            size=$(du -h "$dir/audio.mp3" | cut -f1)
            duration=$(ffprobe -v error -show_entries format=duration \
                -of default=noprint_wrappers=1:nokey=1 "$dir/audio.mp3" 2>/dev/null)
            dur_min=$(LC_NUMERIC=C awk "BEGIN {printf \"%.2f\", $duration/60}" 2>/dev/null)
            
            lyrics=0
            [ -f "$dir/lyrics.txt" ] && lyrics=$(grep -v "^#" "$dir/lyrics.txt" | grep -v "^$" | wc -l)
            
            script="❌"
            [ -f "$dir/blender_script.py" ] && script="✅"
            
            info+="🎵 $name\n   Audio: $size, $dur_min Min\n   Lyrics: $lyrics | Script: $script\n\n"
        fi
    done
    
    kdialog --msgbox "$info"
    show_main_menu
}

cleanup_and_repair() {
    kdialog --msgbox "🧹 AUFRÄUMEN\n\nIch prüfe alle Projekte und repariere sie..."
    
    repaired=0
    for dir in "$PROJECTS_DIR"/*/; do
        if [ -f "$dir/audio.mp3" ] && [ -f "$dir/lyrics.txt" ]; then
            if [ ! -f "$dir/blender_script.py" ]; then
                name=$(basename "$dir")
                duration=$(ffprobe -v error -show_entries format=duration \
                    -of default=noprint_wrappers=1:nokey=1 "$dir/audio.mp3" 2>/dev/null)
                generate_blender_script "$dir" "$name" "2" "$duration" "2"
                repaired=$((repaired + 1))
            fi
        fi
    done
    
    kdialog --msgbox "✅ Aufräumen fertig!\n\n$repaired Projekt(e) repariert"
    show_main_menu
}

# Start
mkdir -p "$PROJECTS_DIR" "$MP3_SOURCE" "$BLENDER_OUTPUT"
show_main_menu
