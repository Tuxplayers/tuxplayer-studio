import bpy
import random
import math

# ===== TUXPLAYER STUDIO - AUTO-GENERATED =====
# Dieses Script wurde automatisch generiert
# Song: {{SONG_NAME}}
# Erstellt am: {{CREATED_DATE}}

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
camera.data.sensor_fit = 'HORIZONTAL'
bpy.context.scene.camera = camera

# Kamera-Bewegung
bpy.context.scene.frame_set(1)
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
text_obj.data.align_y = 'CENTER'
text_obj.data.size = 1.0
text_obj.data.extrude = 0.15
text_obj.rotation_euler = (math.radians(90), 0, 0)

mat_text = bpy.data.materials.new(name="ShinyTextMaterial")
mat_text.use_nodes = True
nodes = mat_text.node_tree.nodes
bsdf = nodes["Principled BSDF"]
bsdf.inputs['Base Color'].default_value = (0, 0.83, 1, 1)
bsdf.inputs['Metallic'].default_value = 0.9
bsdf.inputs['Roughness'].default_value = 0.1
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
    bar.name = f"Bar_{i}"
    bar.scale = (bar_width, bar_width, 1)
    
    mat = bpy.data.materials.new(name=f"BarMaterial_{i}")
    mat.use_nodes = True
    bsdf_bar = mat.node_tree.nodes["Principled BSDF"]
    bsdf_bar.inputs['Base Color'].default_value = colors[i]
    bsdf_bar.inputs['Emission Color'].default_value = colors[i]
    bsdf_bar.inputs['Emission Strength'].default_value = 3.0
    bar.data.materials.append(mat)
    
    bars.append(bar)

# Sinuskurve (Cyan) unten
bpy.ops.curve.primitive_bezier_curve_add(location=(0, 0, -1.5))
sine_curve_cyan = bpy.context.object
sine_curve_cyan.name = "SineWave_Cyan"

curve_data_cyan = sine_curve_cyan.data
curve_data_cyan.dimensions = '3D'
curve_data_cyan.bevel_depth = 0.03
curve_data_cyan.resolution_u = 64

spline_cyan = curve_data_cyan.splines[0]
spline_cyan.bezier_points.add(6)

wave_length = 3.5
amplitude = 0.3
num_points = len(spline_cyan.bezier_points)

for i, point in enumerate(spline_cyan.bezier_points):
    t = i / (num_points - 1)
    x = -wave_length/2 + t * wave_length
    z = amplitude * math.sin(t * math.pi * 3)
    point.co = (x, 0, z)
    point.handle_left_type = 'AUTO'
    point.handle_right_type = 'AUTO'

mat_sine_cyan = bpy.data.materials.new(name="SineCyanMaterial")
mat_sine_cyan.use_nodes = True
bsdf_cyan = mat_sine_cyan.node_tree.nodes["Principled BSDF"]
bsdf_cyan.inputs['Base Color'].default_value = (0.0, 0.737, 0.831, 1)
bsdf_cyan.inputs['Emission Color'].default_value = (0.0, 0.737, 0.831, 1)
bsdf_cyan.inputs['Emission Strength'].default_value = 4.0
sine_curve_cyan.data.materials.append(mat_sine_cyan)

# Sinuskurve (Orange) Mittellinie
bpy.ops.curve.primitive_bezier_curve_add(location=(0, 0, -0.3))
sine_curve_orange = bpy.context.object
sine_curve_orange.name = "SineWave_Orange_Center"

curve_data_orange = sine_curve_orange.data
curve_data_orange.dimensions = '3D'
curve_data_orange.bevel_depth = 0.04
curve_data_orange.resolution_u = 64

spline_orange = curve_data_orange.splines[0]
spline_orange.bezier_points.add(6)

for i, point in enumerate(spline_orange.bezier_points):
    t = i / (num_points - 1)
    x = -wave_length/2 + t * wave_length
    z = amplitude * 0.5 * math.sin(t * math.pi * 2.5)
    point.co = (x, 0, z)
    point.handle_left_type = 'AUTO'
    point.handle_right_type = 'AUTO'

mat_sine_orange = bpy.data.materials.new(name="SineOrangeMaterial")
mat_sine_orange.use_nodes = True
bsdf_orange = mat_sine_orange.node_tree.nodes["Principled BSDF"]
bsdf_orange.inputs['Base Color'].default_value = (1.0, 0.757, 0.027, 1)
bsdf_orange.inputs['Emission Color'].default_value = (1.0, 0.757, 0.027, 1)
bsdf_orange.inputs['Emission Strength'].default_value = 4.0
sine_curve_orange.data.materials.append(mat_sine_orange)

# ===== ANIMATION =====
bpy.context.scene.frame_start = 1
bpy.context.scene.frame_end = ANIMATION_DAUER

# Balken-Animation
for i, bar in enumerate(bars):
    random.seed(i)
    
    for frame in range(1, ANIMATION_DAUER + 1, 2):
        bpy.context.scene.frame_set(frame)
        scale_z = random.uniform(0.5, 3.0)
        bar.scale[2] = scale_z
        bar.keyframe_insert(data_path="scale", index=2, frame=frame)

# ===== LYRICS ANIMATION =====
lyrics_objects = []

for i, lyric_line in enumerate(LYRICS):
    if not lyric_line:
        continue
    
    bpy.ops.object.text_add(location=(0, 0, -2.3))
    lyrics_obj = bpy.context.object
    
    clean_name = lyric_line.replace(" ", "_").replace("–", "-").replace(",", "").replace("'", "")[:30]
    lyrics_obj.name = f"Lyric_{i:03d}_{clean_name}"
    
    lyrics_obj.data.body = lyric_line
    lyrics_obj.data.align_x = 'CENTER'
    lyrics_obj.data.align_y = 'CENTER'
    lyrics_obj.data.size = 0.22
    lyrics_obj.data.resolution_u = 8
    lyrics_obj.data.fill_mode = 'BOTH'
    lyrics_obj.data.extrude = 0.02
    lyrics_obj.rotation_euler = (math.radians(90), 0, 0)
    
    mat_lyric = bpy.data.materials.new(name=f"LyricMat_{i}")
    mat_lyric.use_nodes = True
    bsdf = mat_lyric.node_tree.nodes["Principled BSDF"]
    bsdf.inputs['Base Color'].default_value = (1.0, 1.0, 1.0, 1)
    bsdf.inputs['Emission Color'].default_value = {{LYRICS_COLOR}}
    bsdf.inputs['Emission Strength'].default_value = 3.0
    
    bsdf.inputs['Alpha'].default_value = 0.0
    mat_lyric.blend_method = 'BLEND'
    lyrics_obj.data.materials.append(mat_lyric)
    
    frame_start = 1 + (i * FRAMES_PER_LYRIC)
    frame_fade_in = frame_start + 5
    frame_fade_out = frame_start + FRAMES_PER_LYRIC - 5
    frame_end = frame_start + FRAMES_PER_LYRIC
    
    bpy.context.scene.frame_set(frame_start)
    bsdf.inputs['Alpha'].default_value = 0.0
    bsdf.inputs['Alpha'].keyframe_insert(data_path="default_value", frame=frame_start)
    
    bpy.context.scene.frame_set(frame_fade_in)
    bsdf.inputs['Alpha'].default_value = 1.0
    bsdf.inputs['Alpha'].keyframe_insert(data_path="default_value", frame=frame_fade_in)
    
    bpy.context.scene.frame_set(frame_fade_out)
    bsdf.inputs['Alpha'].default_value = 1.0
    bsdf.inputs['Alpha'].keyframe_insert(data_path="default_value", frame=frame_fade_out)
    
    bpy.context.scene.frame_set(frame_end)
    bsdf.inputs['Alpha'].default_value = 0.0
    bsdf.inputs['Alpha'].keyframe_insert(data_path="default_value", frame=frame_end)
    
    lyrics_objects.append(lyrics_obj)

# Producer Credit - permanent
bpy.ops.object.text_add(location=(0, 0, -3.5))
credit_text = bpy.context.object
credit_text.name = "Producer_Credit"
credit_text.data.body = "Electronic Music Producer • Heiko Schäfer • Stuttgart"
credit_text.data.align_x = 'CENTER'
credit_text.data.align_y = 'CENTER'
credit_text.data.size = 0.13
credit_text.data.resolution_u = 6
credit_text.data.fill_mode = 'BOTH'
credit_text.rotation_euler = (math.radians(90), 0, 0)

mat_credit = bpy.data.materials.new(name="CreditMaterial")
mat_credit.use_nodes = True
bsdf_credit = mat_credit.node_tree.nodes["Principled BSDF"]
bsdf_credit.inputs['Base Color'].default_value = (0.7, 0.7, 0.7, 1)
bsdf_credit.inputs['Emission Color'].default_value = (0.6, 0.6, 0.6, 1)
bsdf_credit.inputs['Emission Strength'].default_value = 0.5
credit_text.data.materials.append(mat_credit)

# ===== RENDER EINSTELLUNGEN =====
bpy.context.scene.render.engine = 'BLENDER_EEVEE_NEXT'
bpy.context.scene.render.resolution_x = 1920
bpy.context.scene.render.resolution_y = 1080
bpy.context.scene.render.fps = FPS
bpy.context.scene.render.film_transparent = False

bpy.context.scene.render.image_settings.file_format = 'FFMPEG'
bpy.context.scene.render.ffmpeg.format = 'MPEG4'
bpy.context.scene.render.ffmpeg.codec = 'H264'
bpy.context.scene.render.ffmpeg.constant_rate_factor = 'HIGH'
bpy.context.scene.render.ffmpeg.audio_codec = 'AAC'
bpy.context.scene.render.filepath = f"//{SONG_NAME.replace(' ', '_')}_tuxplayer.mp4"

try:
    bpy.context.scene.eevee.use_bloom = True
    bpy.context.scene.eevee.bloom_intensity = 0.3
    bpy.context.scene.eevee.bloom_threshold = 0.8
except AttributeError:
    pass

print("\n" + "="*60)
print(f"✅ {SONG_NAME} - TUXPLAYER Visualizer erstellt!")
print("="*60)
print(f"Lyrics: {len(lyrics_objects)} Zeilen")
print(f"Dauer: {ANIMATION_DAUER} Frames ({ANIMATION_DAUER/FPS/60:.1f} min)")
print("="*60)
