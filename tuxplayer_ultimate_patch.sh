#!/bin/bash
# Patch für Backup-Bug

fix_backup() {
    local project_name="$1"
    local project_dir="projects/$project_name"
    
    if [ -f "$project_dir/blender_script.py" ]; then
        # Bereinige Namen für Backup
        local clean_name="${project_name//[^a-zA-Z0-9_]/_}"
        clean_name="${clean_name//__/_}"
        
        local backup_file="/home/heiko/Dokumente/HTML_Webseiten/tuxhs.de/backup/${clean_name}_visualizer.py"
        
        cp "$project_dir/blender_script.py" "$backup_file"
        echo "✅ Backup: $backup_file"
    fi
}

# Fixe alle Projekte
for proj in projects/*/; do
    if [ -f "$proj/blender_script.py" ]; then
        name=$(basename "$proj")
        echo "Backup: $name"
        fix_backup "$name"
    fi
done
