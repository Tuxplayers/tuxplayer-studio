import bpy
import json
import os

# ===== TUXPLAYER STUDIO - TIMESTAMP IMPORTER =====
# Automatischer Import von Whisper-generierten Timestamps
# Projekt: {{PROJECT_DIR}}

TIMESTAMPS_FILE = "{{TIMESTAMPS_FILE}}"
FPS = 30

print("\n" + "="*60)
print("TUXPLAYER Studio - Timestamp Import")
print("="*60)

if not os.path.exists(TIMESTAMPS_FILE):
    print(f"FEHLER: Timestamps-Datei nicht gefunden!")
    print(f"Pfad: {TIMESTAMPS_FILE}")
    print("\nBitte generiere erst Timestamps mit:")
    print("./tuxplayer-studio.sh -> Option 3")
else:
    with open(TIMESTAMPS_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    segments = data.get('segments', [])
    print(f"Geladene Timestamps: {len(segments)} Segmente")
    
    for i, segment in enumerate(segments):
        text = segment.get('text', '').strip()
        start_time = segment.get('start', 0)
        end_time = segment.get('end', 0)
        
        if not text:
            continue
        
        frame_start = int(start_time * FPS)
        frame_end = int(end_time * FPS)
        frame_fade_in = frame_start + 5
        frame_fade_out = frame_end - 5
        
        lyric_obj = None
        obj_name_pattern = f"Lyric_{i:03d}_"
        
        for obj in bpy.data.objects:
            if obj.name.startswith(obj_name_pattern):
                lyric_obj = obj
                break
        
        if not lyric_obj:
            print(f"⚠ Zeile {i} nicht gefunden: {text[:40]}")
            continue
        
        if not lyric_obj.data.materials:
            print(f"⚠ Kein Material: {lyric_obj.name}")
            continue
        
        mat = lyric_obj.data.materials[0]
        if not mat.use_nodes:
            continue
        
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        if not bsdf:
            continue
        
        # Alte Keyframes löschen
        alpha_input = bsdf.inputs['Alpha']
        try:
            if mat.node_tree.animation_data and mat.node_tree.animation_data.action:
                for fc in list(mat.node_tree.animation_data.action.fcurves):
                    if 'Alpha' in fc.data_path:
                        mat.node_tree.animation_data.action.fcurves.remove(fc)
        except:
            pass
        
        # Neue Keyframes setzen
        bpy.context.scene.frame_set(frame_start)
        alpha_input.default_value = 0.0
        alpha_input.keyframe_insert(data_path="default_value", frame=frame_start)
        
        bpy.context.scene.frame_set(frame_fade_in)
        alpha_input.default_value = 1.0
        alpha_input.keyframe_insert(data_path="default_value", frame=frame_fade_in)
        
        bpy.context.scene.frame_set(frame_fade_out)
        alpha_input.default_value = 1.0
        alpha_input.keyframe_insert(data_path="default_value", frame=frame_fade_out)
        
        bpy.context.scene.frame_set(frame_end)
        alpha_input.default_value = 0.0
        alpha_input.keyframe_insert(data_path="default_value", frame=frame_end)
        
        print(f"✓ Zeile {i}: {text[:40]}... -> Frames {frame_start}-{frame_end}")
    
    if segments:
        last_segment = segments[-1]
        total_frames = int(last_segment.get('end', 0) * FPS) + 30
        bpy.context.scene.frame_end = total_frames
        print(f"\nTimeline auf {total_frames} Frames gesetzt")
    
    print("="*60)
    print("FERTIG! Timestamps importiert!")
    print("Drücke Leertaste zum Abspielen")
    print("="*60)
