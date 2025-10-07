import bpy
import random
import math

# ===== AUTOMATISCH GENERIERT =====
SONG_NAME = "{{SONG_NAME}}"
ANIMATION_DAUER = {{DURATION_FRAMES}}  # Frames
FPS = 30

# ===== LYRICS =====
LYRICS = [
{{LYRICS_CONTENT}}
]

FRAMES_PER_LYRIC = {{FRAMES_PER_LYRIC}}

# Szene aufräumen
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

# Welt-Hintergrund (komplett schwarz)
bpy.context.scene.world.use_nodes = True
bg_node = bpy.context.scene.world.node_tree.nodes["Background"]
bg_node.inputs['Color'].default_value = (0.0, 0.0, 0.0, 1)
bg_node.inputs['Strength'].default_value = 0

# Kamera (frontal + sanfte Bewegung)
bpy.ops.object.camera_add(location=(0, -20, 0))
camera = bpy.context.object
camera.rotation_euler = (math.radians(90), 0, 0)
camera.data.lens = 50
bpy.context.scene.camera = camera

# Kamera-Bewegung
camera.location.x = -0.5
camera.keyframe_insert(data_path="location", index=0, frame=1)
bpy.context.scene.frame_set(ANIMATION_DAUER)
camera.location.x = 0.5
camera.keyframe_insert(data_path="location", index=0, frame=ANIMATION_DAUER)

# Haupt-Licht
bpy.ops.object.light_add(type='AREA', location=(0, -12, 0))
main_light = bpy.context.object
main_light.data.energy = 150
main_light.data.size = 10
main_light.rotation_euler = (math.radians(90), 0, 0)

# ===== TEXT "TUXPLAYER" =====
bpy.ops.object.text_add(location=(0, 0, 2.5))
text_obj = bpy.context.object
text_obj.data.body = "TUXPLAYER"
text_obj.data.align_x = 'CENTER'
text_obj.data.size = 1.0
text_obj.data.extrude = 0.15
text_obj.rotation_euler = (math.radians(90), 0, 0)

mat_text = bpy.data.materials.new(name="ShinyTextMaterial")
mat_text.use_nodes = True
bsdf = mat_text.node_tree.nodes["Principled BSDF"]
bsdf.inputs['Base Color'].default_value = (0, 0.83, 1, 1)
bsdf.inputs['Metallic'].default_value = 1.9
bsdf.inputs['Roughness'].default_value = 0.2
bsdf.inputs['Emission Color'].default_value = (0, 0.83, 1, 1)
bsdf.inputs['Emission Strength'].default_value = 2.0
text_obj.data.materials.append(mat_text)

# ===== EQUALIZER BALKEN =====
num_bars = 7
bar_width = 0.35
spacing = 0.7
colors = [
    (0.282, 0.686, 0.314, 1),
    (0.545, 0.765, 0.290, 1),
    (0.804, 0.863, 0.224, 1),
    (1.0, 0.922, 0.231, 1),
    (1.0, 0.757, 0.027, 1),
    (0.0, 0.737, 0.831, 1),
    (0.310, 0.765, 0.969, 1),
]

bars = []
start_x = -(num_bars - 1) * spacing / 2

for i in range(num_bars):
    bpy.ops.mesh.primitive_cube_add(size=1, location=(start_x + i * spacing, 0, -0.3))
    bar = bpy.context.object
    bar.scale = (bar_width, bar_width, 1)
    
    mat = bpy.data.materials.new(name=f"BarMaterial_{i}")
    mat.use_nodes = True
    bsdf_bar = mat.node_tree.nodes["Principled BSDF"]
    bsdf_bar.inputs['Base Color'].default_value = colors[i]
    bsdf_bar.inputs['Emission Color'].default_value = colors[i]
    bsdf_bar.inputs['Emission Strength'].default_value = 3.0
    bar.data.materials.append(mat)
    bars.append(bar)

# ===== ANIMATION =====
bpy.context.scene.frame_start = 1
bpy.context.scene.frame_end = ANIMATION_DAUER

# Balken-Animation
for i, bar in enumerate(bars):
    random.seed(i)
    for frame in range(1, ANIMATION_DAUER + 1, 4):
        bpy.context.scene.frame_set(frame)
        scale_z = random.uniform(0.5, 3.0)
        bar.scale[2] = scale_z
        bar.keyframe_insert(data_path="scale", index=2, frame=frame)

# ===== LYRICS ANIMATION =====
lyrics_color = {{LYRICS_COLOR}}

for i, lyric_line in enumerate(LYRICS):
    if not lyric_line.strip():
        continue
    
    bpy.ops.object.text_add(location=(0, 0, -2.3))
    lyrics_obj = bpy.context.object
    lyrics_obj.data.body = lyric_line
    lyrics_obj.data.align_x = 'CENTER'
    lyrics_obj.data.size = 0.22
    lyrics_obj.data.extrude = 0.02
    lyrics_obj.rotation_euler = (math.radians(90), 0, 0)
    
    mat_lyric = bpy.data.materials.new(name=f"LyricMat_{i}")
    mat_lyric.use_nodes = True
    bsdf = mat_lyric.node_tree.nodes["Principled BSDF"]
    bsdf.inputs['Emission Color'].default_value = lyrics_color
    bsdf.inputs['Emission Strength'].default_value = 3.0
    bsdf.inputs['Alpha'].default_value = 0.0
    mat_lyric.blend_method = 'BLEND'
    lyrics_obj.data.materials.append(mat_lyric)
    
    # Timing
    frame_start = 1 + (i * FRAMES_PER_LYRIC)
    frame_fade_in = frame_start + 5
    frame_fade_out = frame_start + FRAMES_PER_LYRIC - 5
    frame_end = frame_start + FRAMES_PER_LYRIC
    
    bsdf.inputs['Alpha'].default_value = 0.0
    bsdf.inputs['Alpha'].keyframe_insert(data_path="default_value", frame=frame_start)
    bsdf.inputs['Alpha'].default_value = 1.0
    bsdf.inputs['Alpha'].keyframe_insert(data_path="default_value", frame=frame_fade_in)
    bsdf.inputs['Alpha'].default_value = 1.0
    bsdf.inputs['Alpha'].keyframe_insert(data_path="default_value", frame=frame_fade_out)
    bsdf.inputs['Alpha'].default_value = 0.0
    bsdf.inputs['Alpha'].keyframe_insert(data_path="default_value", frame=frame_end)

# Producer Credit
bpy.ops.object.text_add(location=(0, 0, -3.5))
credit_text = bpy.context.object
credit_text.data.body = "Electronic Music Producer • Heiko Schäfer • Stuttgart"
credit_text.data.align_x = 'CENTER'
credit_text.data.size = 0.13
credit_text.rotation_euler = (math.radians(90), 0, 0)

# ===== RENDER EINSTELLUNGEN =====
bpy.context.scene.render.engine = 'BLENDER_EEVEE_NEXT'
bpy.context.scene.render.resolution_x = 1920
bpy.context.scene.render.resolution_y = 1080
bpy.context.scene.render.fps = FPS
bpy.context.scene.render.ffmpeg.format = 'MPEG4'
bpy.context.scene.render.ffmpeg.codec = 'H264'
bpy.context.scene.render.filepath = f"//{SONG_NAME}_tuxplayer.mp4"

print(f"✓ {SONG_NAME} Visualizer erstellt!")
print(f"✓ {len([l for l in LYRICS if l.strip()])} Lyrics-Zeilen")
