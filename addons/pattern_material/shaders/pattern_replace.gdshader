shader_type spatial;
render_mode unshaded, depth_draw_always;

// ============================================================================
// Options
// ============================================================================
group_uniforms Options;
/** Base sprite/model texture containing the mask/artwork to stylize. Uses linear filtering so hard_edges reconstructs smooth curves. */
uniform sampler2D base_texture : source_color, filter_linear_mipmap;
/** When false, ignores base_texture and treats the entire surface as solid white so 3D brushes fill 100% with the pattern. */
uniform bool use_base_texture = true;
/** When true, wraps UV coordinates inside the active frame/texture so tiled 3D meshes repeat cleanly without triggering border outlines. */
uniform bool tile_base_texture = false;
/** Number of horizontal columns in base_texture when using a spritesheet/texture atlas (1 = single image). */
uniform int hframes : hint_range(1, 64, 1) = 1;
/** Number of vertical rows in base_texture when using a spritesheet/texture atlas (1 = single image). */
uniform int vframes : hint_range(1, 64, 1) = 1;
/** Active 0-based sprite frame index (row-major: left-to-right, top-to-bottom). */
uniform int frame : hint_range(0, 1023, 1) = 0;
/** Snap base texture alpha and RGB to hard 0/1 contours using hard_edge_threshold to eliminate edge transparency and gray fringe. */
uniform bool hard_edges = true;
/** Cutoff threshold when hard_edges is enabled. Pixels below this alpha are discarded; pixels at or above become fully opaque. */
uniform float hard_edge_threshold : hint_range(0.0, 1.0, 0.01) = 0.5;
/** Default black-and-white pattern texture (white -> FG color, black -> BG color). */
uniform sampler2D custom_pattern : source_color, filter_nearest, repeat_enable;
group_uniforms;

// ============================================================================
// Base Color Remap (Duotone / Secondary Region Styling)
// ============================================================================
group_uniforms Base_Color_Remap;
/** When enabled, recolors pixels that are NOT matched by the primary pattern mask (e.g., eyes/mouth or secondary duotone paths). */
uniform bool remap_unreplaced = false;
/** Replacement color for unreplaced base pixels when remap_unreplaced is enabled. */
uniform vec4 unreplaced_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
/** When true, fills the unreplaced region with the inverted custom_pattern tinted between bg_color and unreplaced_color. */
uniform bool unreplaced_use_pattern = false;
group_uniforms;

// ============================================================================
// Outline (Post-Palette-Swap Scaling Stroke)
// ============================================================================
group_uniforms Outline;
/** Enables the post-palette-swap outline stroke. */
uniform bool outline_enabled = true;
/** Color and opacity of the outline stroke. */
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
/** Stroke width in texture texels (when outline_scaling is true) or screen pixels (when false). */
uniform float outline_width : hint_range(0.0, 32.0, 0.25) = 3.0;
/** Placement of the stroke relative to the contour: Center (2, default) straddles both inside and outside to hide jagged seams. */
uniform int outline_mode : hint_enum("Outer:0,Inner:1,Center (Hide Edge):2") = 2;
/** Anti-aliasing smoothness where the inner edge of the stroke meets the pattern (0 = hard step). */
uniform float outline_smoothness : hint_range(0.0, 0.25, 0.01) = 0.02;
/** When true (default), the stroke scales naturally with the mesh in 3D space. */
uniform bool outline_scaling = true;
/** Also draw outline strokes along internal color boundaries within the base texture. */
uniform bool outline_internal_edges = false;
/** Color difference threshold for internal edge detection when outline_internal_edges is enabled. */
uniform float outline_internal_threshold : hint_range(0.01, 1.0, 0.01) = 0.25;
/** Visual fill mode for the outline stroke: Solid Color (0), Inverted Pattern (1), or FG/BG Alternating Dash (2). */
uniform int outline_color_mode : hint_enum("Solid Color:0,Inverted Pattern:1,FG/BG Alternating Dash:2") = 0;
/** Amplitude of 90s hand-drawn "boiling line" (Squigglevision) thickness wobble. */
uniform float outline_boil_amp : hint_range(0.0, 1.0, 0.01) = 0.0;
/** Spatial frequency of the boiling outline wave around the contour. */
uniform float outline_boil_freq : hint_range(1.0, 30.0, 0.5) = 8.0;
group_uniforms;

// ============================================================================
// Bevel, Emboss & 3D Fresnel Rim
// ============================================================================
group_uniforms Bevel_And_Rim;
/** Enables Win98 / enamel-pin inner bevel & emboss lighting using the free 16-direction contour normal. */
uniform bool bevel_enabled = false;
/** Light source angle in radians for the contour bevel (default 2.356 = 135 deg top-left). */
uniform float bevel_angle : hint_range(0.0, 6.28318, 0.05) = 2.356;
/** Intensity of the inner bevel highlight and shadow along the contour. */
uniform float bevel_strength : hint_range(0.0, 1.0, 0.01) = 0.5;
/** Highlight color on edges facing the bevel light angle. */
uniform vec4 bevel_light_color : source_color = vec4(1.0, 1.0, 1.0, 0.8);
/** Shadow color on edges facing away from the bevel light angle. */
uniform vec4 bevel_shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.8);
/** Enables 3D view-angle Fresnel rim effect on curved 3D geometry. */
uniform bool fresnel_enabled = false;
/** Falloff exponent for the 3D Fresnel rim (higher = tighter edge rim). */
uniform float fresnel_power : hint_range(0.5, 8.0, 0.1) = 2.5;
/** Rim tint color applied at grazing 3D viewing angles. */
uniform vec4 fresnel_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
/** When true, dynamically inverts the pattern FG/BG colors inside the Fresnel rim band. */
uniform bool fresnel_invert_pattern = false;
group_uniforms;

// ============================================================================
// Drop Shadow (2.5D Paper Cutout / Block Shadow)
// ============================================================================
group_uniforms Drop_Shadow;
/** Enables a 2.5D offset paper-cutout drop shadow behind the sprite silhouette. */
uniform bool shadow_enabled = false;
/** Color and opacity of the offset drop shadow (defaults to Afterlife 98 palette deep indigo). */
uniform vec4 shadow_color : source_color = vec4(0.184314, 0.145098, 0.337255, 1.0);
/** Shadow offset in texture texels (when outline_scaling is true) or screen pixels (when false). */
uniform vec2 shadow_offset = vec2(4.0, -4.0);
group_uniforms;

// ============================================================================
// Pattern Slot
// ============================================================================
group_uniforms Pattern;
/** What color/channel to replace with our pattern (defaults to G = 1). */
uniform int replace_mode : hint_enum("R:0,G:1,B:2,A:3,White:4,Custom Color:5") = 1;
/** Target color to replace when replace_mode is Custom Color (5). */
uniform vec4 replace_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
/** Matching threshold for channel/color replacement. */
uniform float threshold : hint_range(0.01, 1.0, 0.01) = 0.5;
/** Replaces white pixels in the black-and-white pattern. */
uniform vec4 fg_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
/** Replaces black pixels in the black-and-white pattern. */
uniform vec4 bg_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
/** Swaps black and white in the sampled pattern before applying FG/BG colors. */
uniform bool invert_pattern = false;
/** Blend mode used when compositing the pattern onto the matched region. */
uniform int pattern_blend_mode : hint_enum("Replace (Mix):0,Multiply:1,Screen:2,Overlay:3,Add:4,Difference:5") = 0;
/** Opacity multiplier for the pattern replacement layer. */
uniform float pattern_opacity : hint_range(0.0, 1.0, 0.01) = 1.0;
group_uniforms;

group_uniforms Pattern.Transform_Base;
/** Perspective Normals: Camera (0), Model Normals (1), World Triplanar (2), Mesh UV (3), or Cylindrical (4). */
uniform int perspective_normals : hint_enum("Camera:0,Model Normals:1,World Triplanar:2,Mesh UV:3,Cylindrical:4") = 0;
/** Scaling vs nonscaling: when true, getting close makes the texture scale. */
uniform bool scaling = true;
/** Scale factor mult (1x). */
uniform float scale_factor_mult = 1.0;
/** Independent X/Y non-uniform scale factor. */
uniform vec2 non_uniform_scale = vec2(1.0, 1.0);
/** Static UV offset applied before motion. */
uniform vec2 static_offset = vec2(0.0, 0.0);
/** Static rotation angle (radians). */
uniform float static_rotation = 0.0;
/** Flip pattern horizontally. */
uniform bool flip_x = false;
/** Flip pattern vertically. */
uniform bool flip_y = false;
/** Mirror every alternate tile for seamless kaleidoscopic tiling. */
uniform bool mirror_tiles = false;
group_uniforms;

group_uniforms Pattern.Position_Motion;
/** Position.(x/y) X Time multiplier (0): linear drift speed over time. */
uniform vec2 pos_time_mult = vec2(0.0, 0.0);
/** Periodic wave oscillation mode for position. */
uniform int pos_wave_mode : hint_enum("None:0,Sin:1,Cos:2,Circular Orbit (Cos X / Sin Y):3,PingPong Triangle:4") = 0;
/** Amplitude of position wave oscillation on X and Y. */
uniform vec2 pos_wave_amp = vec2(0.25, 0.25);
/** Frequency of position wave oscillation on X and Y. */
uniform vec2 pos_wave_freq = vec2(1.0, 1.0);
/** Phase offset (radians) for position wave on X and Y. */
uniform vec2 pos_wave_phase = vec2(0.0, 0.0);
group_uniforms;

group_uniforms Pattern.Rotation_Motion;
/** Rotation X Time multiplier (0): continuous angular speed (radians/sec). */
uniform float rot_time_mult = 0.0;
/** Periodic pendulum oscillation mode for rotation. */
uniform int rot_wave_mode : hint_enum("None:0,Sin:1,Cos:2,PingPong Triangle:3") = 0;
/** Amplitude of rotation wave swing (radians). */
uniform float rot_wave_amp = 0.5;
/** Frequency of rotation wave oscillation. */
uniform float rot_wave_freq = 1.0;
group_uniforms;

group_uniforms Pattern.Scale_Pulse;
/** Periodic breathing/pulsing mode for pattern scale. */
uniform int scale_wave_mode : hint_enum("None:0,Sin:1,Cos:2,Abs Sin (Bounce):3,PingPong Triangle:4") = 0;
/** Amplitude of scale pulsing on X and Y. */
uniform vec2 scale_wave_amp = vec2(0.25, 0.25);
/** Frequency of scale pulsing on X and Y. */
uniform vec2 scale_wave_freq = vec2(1.0, 1.0);
group_uniforms;

group_uniforms Pattern.Spatial_Ripple;
/** Enables spatial UV wave/ripple distortion across the pattern. */
uniform bool ripple_enabled = false;
/** Spatial distortion waveform mode. */
uniform int ripple_mode : hint_enum("Sin X / Sin Y (Cross Wave):0,Sin Y -> X / Cos X -> Y (Liquid Shear):1,Radial Ripple:2") = 0;
/** UV distortion amplitude on X and Y. */
uniform vec2 ripple_amp = vec2(0.05, 0.05);
/** Spatial wave frequency across UV space. */
uniform vec2 ripple_freq = vec2(6.0, 6.0);
/** Ripple animation speed over time. */
uniform vec2 ripple_speed = vec2(2.0, 2.0);
group_uniforms;

group_uniforms Pattern.Time_Options;
/** Steps TIME to fixed FPS intervals for a choppy 90s / stop-motion animation feel. */
uniform bool quantize_time = false;
/** Frame rate used when quantize_time is enabled. */
uniform float time_fps : hint_range(1.0, 60.0, 0.5) = 12.0;
group_uniforms;

// ============================================================================
// Retro 98 Stylization FX (Bayer Dither, Pattern Dissolve, Glitch & Scanlines)
// ============================================================================
group_uniforms Stylization_FX;
/** Enables ordered 4x4 Bayer matrix dithering on pattern transitions and shading. */
uniform bool dither_enabled = false;
/** Strength of the 4x4 Bayer dither threshold modulation. */
uniform float dither_strength : hint_range(0.0, 1.0, 0.05) = 0.5;
/** Screen pixel size of each Bayer dither cell (1 = native pixel, 2..4 = chunky retro dither). */
uniform float dither_pixel_size : hint_range(1.0, 16.0, 1.0) = 2.0;
/** Dissolve wipe progress (0 = fully visible, 1 = fully dissolved). Uses pattern + Bayer matrix. */
uniform float dissolve_amount : hint_range(0.0, 1.0, 0.01) = 0.0;
/** Width of the glowing/colored burn rim along the dissolve boundary. */
uniform float dissolve_edge_width : hint_range(0.0, 0.25, 0.01) = 0.05;
/** Color of the dissolve boundary edge. */
uniform vec4 dissolve_edge_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
/** Horizontal VHS / CRT tear glitch intensity (0 = disabled). */
uniform float glitch_intensity : hint_range(0.0, 1.0, 0.01) = 0.0;
/** CRT / 90s monitor scanline darkening/inversion intensity (0 = disabled). */
uniform float scanline_strength : hint_range(0.0, 1.0, 0.01) = 0.0;
/** Number of horizontal scanlines across the screen/surface. */
uniform float scanline_density : hint_range(10.0, 480.0, 1.0) = 120.0;
/** Self-illumination / emission multiplier for WorldEnvironment glow/bloom (0 = unlit albedo only). */
uniform float emission_strength : hint_range(0.0, 8.0, 0.05) = 0.0;
group_uniforms;

// ============================================================================
// Transparency & Backdrop Effects (Screen-Space Blend, Refraction & Lens FX)
// ============================================================================
group_uniforms Transparency_And_Backdrop;
/** Master opacity multiplier for the entire material result (1.0 = opaque, 0.0 = invisible). */
uniform float master_opacity : hint_range(0.0, 1.0, 0.01) = 1.0;
/** When true, fg_color.a, bg_color.a, pattern_opacity, and unreplaced_color.a control actual surface transparency (so alpha = 0 cuts see-through holes). */
uniform bool pattern_alpha_affects_surface = true;
/** When true, the outline stroke stays at outline_color.a even when master_opacity or interior pattern alpha is reduced. */
uniform bool outline_ignores_master_opacity = false;
/** Pixels with final alpha at or below this threshold are discarded so they do not write to depth. */
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0, 0.001) = 0.001;
/** Converts partial transparency into a 90s 4x4 Bayer screen-door cutout (order-independent, zero depth sorting artifacts). */
uniform bool opacity_dither_enabled = false;
/** Screen-space blend/filter mode applied to objects behind this material. */
uniform int backdrop_blend_mode : hint_enum("Standard Alpha:0,Multiply (Stained Glass):1,Screen / Add (Hologram Glow):2,Overlay (Contrast Tint):3,Difference / Invert (X-Ray):4,Duotone Palette Lens (BG/FG Map):5,Pattern Mask Invert:6") = 0;
/** Warps the background behind this material using the animated pattern and contour bevel normal (-1..1). */
uniform float backdrop_refraction : hint_range(-1.0, 1.0, 0.01) = 0.0;
/** Pixelates objects seen behind this material into chunky NxN pixel blocks (1 = no pixelation). */
uniform float backdrop_pixel_size : hint_range(1.0, 64.0, 1.0) = 1.0;
/** Frosted glass mipmap blur LOD for objects seen behind this material (0 = sharp, 1..5 = blurry). */
uniform float backdrop_blur_lod : hint_range(0.0, 5.0, 0.1) = 0.0;
/** Prismatic RGB split applied to objects seen behind this material. */
uniform float backdrop_chromatic_aberration : hint_range(0.0, 0.1, 0.001) = 0.0;
/** Captures the rendered 3D scene behind this material for refraction, blurring, and backdrop filtering. */
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
group_uniforms;

// ============================================================================
// Vertex FX (Billboarding, 3D Waves, Paper Cutout Sway & PS1 Vertex Snap)
// ============================================================================
group_uniforms Vertex_FX;
/** Optional camera billboarding for 2.5D sprite cards: Disabled (0), Full Billboard (1), or Y-Billboard Upright (2). */
uniform int billboard_mode : hint_enum("Disabled:0,Full Billboard:1,Y-Billboard (Upright):2") = 0;
/** Procedural vertex animation mode: Disabled (0), 3D Surface Waves (1), 2.5D Paper Sway/Skew (2), or Breathing Squash & Stretch (3). */
uniform int vertex_motion_mode : hint_enum("Disabled:0,3D Surface Waves (Y):1,2.5D Paper Sway / Skew:2,Breathing Squash & Stretch:3") = 0;
/** Amplitude of vertex wave / sway displacement. */
uniform vec2 vertex_wave_amp = vec2(0.08, 0.08);
/** Spatial frequency of vertex wave displacement. */
uniform vec2 vertex_wave_freq = vec2(2.0, 2.0);
/** Animation speed of vertex motion. */
uniform float vertex_wave_speed = 2.0;
/** Snaps vertices to a discrete view-space grid for retro PS1 / 98 low-precision jitter. */
uniform bool vertex_snap_enabled = false;
/** Grid resolution for vertex snapping when vertex_snap_enabled is true. */
uniform float vertex_snap_resolution : hint_range(16.0, 512.0, 1.0) = 160.0;
group_uniforms;

varying vec3 v_local_pos;
varying vec3 v_local_normal;
varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying vec3 v_node_view_center;

float get_effective_time(float raw_time) {
  return quantize_time ? (floor(raw_time * max(time_fps, 1.0)) / max(time_fps, 1.0)) : raw_time;
}

void vertex() {
  float t = get_effective_time(TIME);

  // 1. Optional Billboarding (transforms VERTEX/NORMAL in local space without overriding MODELVIEW_MATRIX)
  if (billboard_mode == 1) {
    mat3 cam_basis = mat3(
      normalize(INV_VIEW_MATRIX[0].xyz) * length(MODEL_MATRIX[0].xyz),
      normalize(INV_VIEW_MATRIX[1].xyz) * length(MODEL_MATRIX[1].xyz),
      normalize(INV_VIEW_MATRIX[2].xyz) * length(MODEL_MATRIX[2].xyz)
    );
    mat3 inv_model = inverse(mat3(MODEL_MATRIX));
    VERTEX = inv_model * (cam_basis * VERTEX);
    NORMAL = normalize(inv_model * normalize(INV_VIEW_MATRIX[2].xyz));
  } else if (billboard_mode == 2) {
    vec3 cam_forward = normalize(vec3(INV_VIEW_MATRIX[2].x, 0.0, INV_VIEW_MATRIX[2].z));
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(up, cam_forward));
    mat3 y_basis = mat3(
      right * length(MODEL_MATRIX[0].xyz),
      up * length(MODEL_MATRIX[1].xyz),
      cam_forward * length(MODEL_MATRIX[2].xyz)
    );
    mat3 inv_model = inverse(mat3(MODEL_MATRIX));
    VERTEX = inv_model * (y_basis * VERTEX);
    NORMAL = normalize(inv_model * cam_forward);
  }

  // 2. Procedural Vertex Motion (3D Water Waves, 2.5D Paper Sway, Breathing Squash/Stretch)
  if (vertex_motion_mode == 1) {
    // 3D Surface Waves (ideal for water.material / liquids / portals)
    float w_x = sin(VERTEX.x * vertex_wave_freq.x + t * vertex_wave_speed) * vertex_wave_amp.x;
    float w_z = cos(VERTEX.z * vertex_wave_freq.y + t * vertex_wave_speed * 0.85) * vertex_wave_amp.y;
    VERTEX.y += w_x + w_z;
  } else if (vertex_motion_mode == 2) {
    // 2.5D Paper Cutout Sway / Skew (anchored near bottom of quad)
    float height_factor = clamp(VERTEX.y + 0.5, 0.0, 2.0);
    VERTEX.x += sin(t * vertex_wave_speed + VERTEX.y * vertex_wave_freq.x) * vertex_wave_amp.x * height_factor;
    VERTEX.z += cos(t * vertex_wave_speed * 0.7 + VERTEX.x * vertex_wave_freq.y) * vertex_wave_amp.y * height_factor;
  } else if (vertex_motion_mode == 3) {
    // Breathing Squash & Stretch
    float s = sin(t * vertex_wave_speed);
    VERTEX.x *= 1.0 + s * vertex_wave_amp.x;
    VERTEX.y *= 1.0 - s * vertex_wave_amp.y;
  }

  // 3. Optional Retro PS1 / 98 Vertex Grid Snapping (operates on VERTEX so POSITION is never overridden)
  if (vertex_snap_enabled) {
    float snap_step = 4.0 / max(vertex_snap_resolution, 16.0);
    VERTEX = floor(VERTEX / snap_step + 0.5) * snap_step;
  }

  v_local_pos = VERTEX;
  v_local_normal = NORMAL;
  v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
  v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
  v_node_view_center = (VIEW_MATRIX * MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
}

/**
 * Evaluates a 1D periodic waveform:
 * 1 = Sin, 2 = Cos, 3 = Abs(Sin), 4 = PingPong Triangle [-1, 1]
 */
float eval_triangle_wave(float phase) {
  return 1.0 - 4.0 * abs(fract(phase / (2.0 * PI) + 0.25) - 0.5);
}

/**
 * Evaluates ordered 4x4 Bayer matrix value in [0, 1] for screen/UV coordinates.
 */
float eval_bayer4x4(vec2 pixel_coord) {
  ivec2 p = ivec2(mod(floor(pixel_coord / max(dither_pixel_size, 1.0)), 4.0));
  int idx = p.y * 4 + p.x;
  const float bayer[16] = float[16](
     0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0,
    12.0 / 16.0,  4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0,
     3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0,
    15.0 / 16.0,  7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0
  );
  return bayer[clamp(idx, 0, 15)];
}

/**
 * Simple deterministic 1D hash for glitch bursts.
 */
float hash11(float p) {
  p = fract(p * 0.1031);
  p *= p + 33.33;
  p *= p + p;
  return fract(p);
}

/**
 * Evaluates whether `base_col` matches the target channel or color for the pattern slot.
 */
float compute_replace_mask(vec4 base_col, int mode, vec4 target_color, float thresh) {
  if (base_col.a <= 0.001) {
    return 0.0;
  }
  if (mode == 0) {
    return step(thresh, base_col.r);
  } else if (mode == 1) {
    return step(thresh, base_col.g);
  } else if (mode == 2) {
    return step(thresh, base_col.b);
  } else if (mode == 3) {
    return step(thresh, base_col.a);
  } else if (mode == 4) {
    float min_rgb = min(base_col.r, min(base_col.g, base_col.b));
    return step(thresh, min_rgb);
  } else {
    float dist = distance(base_col.rgb, target_color.rgb);
    return 1.0 - step(thresh, dist);
  }
}

/**
 * Projects 2D coordinates onto a dominant-axis box plane using position & normal.
 */
vec2 project_model_normal_plane(vec3 pos, vec3 n, vec2 mesh_uv) {
  vec3 an = abs(normalize(n));
  if (an.z >= an.x && an.z >= an.y) {
    return pos.xy;
  } else if (an.x >= an.y && an.x >= an.z) {
    return pos.zy;
  } else {
    return pos.xz;
  }
}

/**
 * Computes transformed pattern UV coordinates with full support for:
 * - Time quantization (FPS stepper)
 * - Perspective Normals (Camera, Model Normals, World Triplanar, Mesh UV, Cylindrical) & Scaling vs Non-scaling
 * - Scale factor mult, Non-uniform scale, and Scale Pulse (Sin/Cos/Bounce/PingPong)
 * - Static Rotation, Linear Rotation Spin, and Rotation Wave Swing (Sin/Cos/PingPong)
 * - Static Offset, Linear Position Drift, and Position Wave Oscillation (Sin/Cos/Orbit/PingPong)
 * - Spatial Wave / Ripple UV distortion & Horizontal Glitch
 * - Flip X/Y and Mirror Alternate Tiles
 */
vec2 compute_pattern_uv_full(
  vec2 mesh_uv,
  vec3 local_pos,
  vec3 local_normal,
  vec3 world_pos,
  vec3 world_normal,
  vec3 view_pos,
  vec3 node_view_center,
  vec2 screen_uv,
  vec2 viewport_size,
  float raw_time
) {
  float t = get_effective_time(raw_time);
  float aspect = viewport_size.x / max(viewport_size.y, 1.0);
  float cam_depth = max(-view_pos.z, 0.0001);
  vec2 uv;

  // 1. 3D Projection (Camera / Model Normals / World Triplanar / Mesh UV / Cylindrical)
  if (perspective_normals == 0) {
    if (scaling) {
      uv = (view_pos.xy - node_view_center.xy);
    } else {
      uv = (screen_uv - vec2(0.5)) * vec2(aspect, 1.0) * 2.0;
    }
  } else if (perspective_normals == 1) {
    vec2 surface_uv = project_model_normal_plane(local_pos, local_normal, mesh_uv);
    uv = scaling ? surface_uv : (surface_uv * cam_depth);
  } else if (perspective_normals == 2) {
    vec2 world_uv = project_model_normal_plane(world_pos, world_normal, mesh_uv);
    uv = scaling ? world_uv : (world_uv * cam_depth);
  } else if (perspective_normals == 3) {
    vec2 centered_mesh_uv = mesh_uv - vec2(0.5);
    uv = scaling ? centered_mesh_uv : (centered_mesh_uv * cam_depth);
  } else {
    float angle_u = atan(local_pos.x, local_pos.z) / (2.0 * PI);
    vec2 cyl_uv = vec2(angle_u, local_pos.y);
    uv = scaling ? cyl_uv : (cyl_uv * cam_depth);
  }

  // 2. Flip X / Y
  if (flip_x) {
    uv.x = -uv.x;
  }
  if (flip_y) {
    uv.y = -uv.y;
  }

  // 3. Scale Factor Mult + Non-Uniform Scale + Scale Pulse Wave
  vec2 eff_scale = non_uniform_scale * scale_factor_mult;
  if (scale_wave_mode != 0) {
    vec2 sp = t * scale_wave_freq;
    vec2 sw = vec2(0.0);
    if (scale_wave_mode == 1) {
      sw = sin(sp);
    } else if (scale_wave_mode == 2) {
      sw = cos(sp);
    } else if (scale_wave_mode == 3) {
      sw = abs(sin(sp));
    } else if (scale_wave_mode == 4) {
      sw = vec2(eval_triangle_wave(sp.x), eval_triangle_wave(sp.y));
    }
    eff_scale *= (vec2(1.0) + sw * scale_wave_amp);
  }
  uv *= eff_scale;

  // 4. Static Rotation + Linear Rotation + Rotation Wave Swing
  float angle = static_rotation + rot_time_mult * t;
  if (rot_wave_mode != 0) {
    float rp = t * rot_wave_freq;
    float rw = 0.0;
    if (rot_wave_mode == 1) {
      rw = sin(rp);
    } else if (rot_wave_mode == 2) {
      rw = cos(rp);
    } else if (rot_wave_mode == 3) {
      rw = eval_triangle_wave(rp);
    }
    angle += rw * rot_wave_amp;
  }
  if (abs(angle) > 0.00001) {
    float s = sin(angle);
    float c = cos(angle);
    uv = mat2(vec2(c, -s), vec2(s, c)) * uv;
  }

  // 5. Static Offset + Linear Position Drift + Position Wave Oscillation
  vec2 pos_offset = static_offset + pos_time_mult * t;
  if (pos_wave_mode != 0) {
    vec2 pp = t * pos_wave_freq + pos_wave_phase;
    vec2 pw = vec2(0.0);
    if (pos_wave_mode == 1) {
      pw = sin(pp);
    } else if (pos_wave_mode == 2) {
      pw = cos(pp);
    } else if (pos_wave_mode == 3) {
      // Circular / Lissajous Orbit: Cos on X, Sin on Y
      pw = vec2(cos(pp.x), sin(pp.y));
    } else if (pos_wave_mode == 4) {
      pw = vec2(eval_triangle_wave(pp.x), eval_triangle_wave(pp.y));
    }
    pos_offset += pw * pos_wave_amp;
  }
  uv += pos_offset;

  // 6. Spatial Wave / Ripple UV Distortion
  if (ripple_enabled) {
    if (ripple_mode == 0) {
      // Cross wave: Sin(X) on X, Sin(Y) on Y
      uv.x += sin(uv.x * ripple_freq.x + t * ripple_speed.x) * ripple_amp.x;
      uv.y += sin(uv.y * ripple_freq.y + t * ripple_speed.y) * ripple_amp.y;
    } else if (ripple_mode == 1) {
      // Liquid shear: Y warps X via Sin, X warps Y via Cos
      vec2 base_uv = uv;
      uv.x += sin(base_uv.y * ripple_freq.y + t * ripple_speed.x) * ripple_amp.x;
      uv.y += cos(base_uv.x * ripple_freq.x + t * ripple_speed.y) * ripple_amp.y;
    } else if (ripple_mode == 2) {
      // Radial ripple from center
      float r = length(uv);
      vec2 dir = (r > 0.0001) ? (uv / r) : vec2(1.0, 0.0);
      uv += dir * sin(r * ripple_freq.x - t * ripple_speed.x) * ripple_amp;
    }
  }

  // 7. Optional Horizontal VHS / CRT Glitch Jitter
  if (glitch_intensity > 0.0) {
    float band = floor(uv.y * 24.0 + t * 7.0);
    float h = hash11(band + floor(t * 15.0) * 19.19);
    if (h > (1.0 - glitch_intensity * 0.45)) {
      uv.x += (h - 0.5) * glitch_intensity * 0.6;
    }
  }

  uv += vec2(0.5);

  // 8. Alternate Tile Mirroring
  if (mirror_tiles) {
    uv = abs(fract(uv * 0.5) * 2.0 - 1.0);
  }

  return uv;
}

/**
 * Samples the black-and-white pattern, optionally inverts it, and maps black -> bg_color, white -> fg_color.
 */
vec4 evaluate_pattern_color(vec4 pat_sample, vec4 fg_col, vec4 bg_col, bool inv_pat, float bayer_val) {
  float pat_bw = dot(pat_sample.rgb, vec3(0.299, 0.587, 0.114));
  if (dither_enabled) {
    pat_bw = clamp(pat_bw + (bayer_val - 0.5) * dither_strength, 0.0, 1.0);
  }
  if (hard_edges) {
    pat_bw = step(0.5, pat_bw);
  }
  if (inv_pat) {
    pat_bw = 1.0 - pat_bw;
  }
  return mix(bg_col, fg_col, pat_bw);
}

/**
 * Applies the selected blend mode between `base_rgb` and `pat_rgb`.
 */
vec3 apply_pattern_blend(vec3 base_rgb, vec3 pat_rgb, int mode) {
  if (mode == 1) {
    return base_rgb * pat_rgb;
  } else if (mode == 2) {
    return vec3(1.0) - (vec3(1.0) - base_rgb) * (vec3(1.0) - pat_rgb);
  } else if (mode == 3) {
    return mix(
      2.0 * base_rgb * pat_rgb,
      vec3(1.0) - 2.0 * (vec3(1.0) - base_rgb) * (vec3(1.0) - pat_rgb),
      step(vec3(0.5), base_rgb)
    );
  } else if (mode == 4) {
    return min(base_rgb + pat_rgb, vec3(1.0));
  } else if (mode == 5) {
    return abs(base_rgb - pat_rgb);
  }
  return pat_rgb;
}

/**
 * Evaluates the effective alpha of a base texture texel, applying hard_edges cutoff if enabled.
 */
float evaluate_base_alpha(float a) {
  if (hard_edges) {
    return (a < hard_edge_threshold || a <= 0.0) ? 0.0 : 1.0;
  }
  return a;
}

/**
 * Returns the canonical target RGB color for the active replace_mode.
 */
vec3 get_target_rgb(int mode, vec4 target_color, vec3 raw_rgb) {
  if (mode == 0) {
    return vec3(1.0, 0.0, 0.0);
  } else if (mode == 1) {
    return vec3(0.0, 1.0, 0.0);
  } else if (mode == 2) {
    return vec3(0.0, 0.0, 1.0);
  } else if (mode == 4) {
    return vec3(1.0, 1.0, 1.0);
  } else if (mode == 5) {
    return target_color.rgb;
  }
  return raw_rgb;
}

/**
 * Snaps base texture RGB channels at hard_edge_threshold when hard_edges is enabled,
 * turning bilinearly-filtered transitions into smooth contours of pure 0/1 colors
 * so tight thresholds (e.g. 0.01) leave zero unreplaced gray fringe.
 * For grayscale / low-chroma pixels (including S3TC RGB565 5-bit R/B vs 6-bit G jitter),
 * all three channels are snapped together via scalar luminance so contours never split
 * into false green (0, 1, 0) or purple (1, 0, 1) artifacts.
 */
vec3 evaluate_base_rgb(vec3 rgb) {
  if (hard_edges) {
    float max_c = max(rgb.r, max(rgb.g, rgb.b));
    float min_c = min(rgb.r, min(rgb.g, rgb.b));
    if (max_c - min_c < 0.15) {
      float luma = dot(rgb, vec3(0.299, 0.587, 0.114));
      return vec3(step(hard_edge_threshold, luma));
    }
    return step(vec3(hard_edge_threshold), rgb);
  }
  return rgb;
}

/**
 * Converts a 2D pixel/texel offset into a surface UV offset.
 * When outline_scaling is true (default), steps in texture UV space so the stroke scales naturally with the mesh.
 */
vec2 compute_outline_uv_offset(vec2 offset_px, vec2 duv_dx, vec2 duv_dy) {
  if (outline_scaling) {
    vec2 tex_size = max(vec2(textureSize(base_texture, 0)), vec2(1.0));
    return offset_px / tex_size;
  }
  return duv_dx * offset_px.x + duv_dy * offset_px.y;
}

/**
 * Evaluates the post-palette-swap scaling stroke AND free 2D contour normal using
 * morphological dilation/erosion across a 16-direction, 3-ring circular disk in UV space.
 * Returns vec4(stroke_factor, dilated_alpha, contour_normal.x, contour_normal.y).
 */
vec4 evaluate_outline_stroke(
  vec2 uv,
  vec2 cell_uv_min,
  vec2 cell_uv_max,
  bool wrap_cell,
  vec4 raw_base_col,
  float base_alpha,
  vec2 duv_dx,
  vec2 duv_dy,
  float raw_time
) {
  bool need_ring = (outline_enabled && outline_width > 0.0) || bevel_enabled;
  if (!need_ring || !use_base_texture) {
    return vec4(0.0, base_alpha, 0.0, 0.0);
  }

  float t = get_effective_time(raw_time);
  float eff_width = (outline_enabled && outline_width > 0.0) ? outline_width : 2.0;
  float max_r = (outline_mode == 2) ? (eff_width * 0.5) : eff_width;

  if (outline_boil_amp > 0.0) {
    float boil = sin(uv.x * outline_boil_freq * 6.28318 + t * 12.0) * cos(uv.y * outline_boil_freq * 6.28318 - t * 9.0);
    max_r *= max(0.1, 1.0 + boil * outline_boil_amp);
  }

  // 16 evenly spaced directions around the unit circle (every 22.5 degrees)
  const vec2 dirs[16] = vec2[16](
    vec2(1.0, 0.0),
    vec2(0.92387953, 0.38268343),
    vec2(0.70710678, 0.70710678),
    vec2(0.38268343, 0.92387953),
    vec2(0.0, 1.0),
    vec2(-0.38268343, 0.92387953),
    vec2(-0.70710678, 0.70710678),
    vec2(-0.92387953, 0.38268343),
    vec2(-1.0, 0.0),
    vec2(-0.92387953, -0.38268343),
    vec2(-0.70710678, -0.70710678),
    vec2(-0.38268343, -0.92387953),
    vec2(0.0, -1.0),
    vec2(0.38268343, -0.92387953),
    vec2(0.70710678, -0.70710678),
    vec2(0.92387953, -0.38268343)
  );

  float min_a = raw_base_col.a;
  float max_a = raw_base_col.a;
  float center_luma = dot(raw_base_col.rgb, vec3(0.299, 0.587, 0.114));
  float max_color_diff = 0.0;
  vec2 contour_grad = vec2(0.0);
  vec2 cell_span = max(cell_uv_max - cell_uv_min, vec2(0.00001));

  for (int ring = 1; ring <= 3; ring++) {
    float r = max_r * (float(ring) / 3.0);
    for (int i = 0; i < 16; i++) {
      vec2 sample_uv = uv + compute_outline_uv_offset(dirs[i] * r, duv_dx, duv_dy);
      bool out_of_bounds = (!wrap_cell) && (sample_uv.x < cell_uv_min.x || sample_uv.x > cell_uv_max.x || sample_uv.y < cell_uv_min.y || sample_uv.y > cell_uv_max.y);
      vec2 eff_uv = wrap_cell ? (cell_uv_min + fract((sample_uv - cell_uv_min) / cell_span) * cell_span) : sample_uv;
      vec4 n_col = out_of_bounds ? vec4(0.0) : textureLod(base_texture, eff_uv, 0.0);
      float n_a = out_of_bounds ? 0.0 : n_col.a;

      min_a = min(min_a, n_a);
      max_a = max(max_a, n_a);
      contour_grad += dirs[i] * (raw_base_col.a - n_a);

      if (outline_internal_edges && !out_of_bounds && n_a >= hard_edge_threshold && raw_base_col.a >= hard_edge_threshold) {
        float n_luma = dot(n_col.rgb, vec3(0.299, 0.587, 0.114));
        max_color_diff = max(max_color_diff, abs(center_luma - n_luma));
      }
    }
  }

  if (!outline_enabled || outline_width <= 0.0) {
    return vec4(0.0, base_alpha, contour_grad.x, contour_grad.y);
  }

  float cutoff = hard_edges ? hard_edge_threshold : 0.5;
  float soft = max(outline_smoothness, 0.0001);

  // Dilated silhouette presence (1 inside dilated shape, 0 outside)
  float is_dilated = (max_a >= cutoff && max_a > 0.0) ? 1.0 : 0.0;
  // Eroded interior presence (0 in the stroke border band, 1 deep inside the interior)
  float eroded_interior = (outline_smoothness > 0.0)
    ? smoothstep(cutoff - soft, cutoff + soft, min_a)
    : ((min_a >= cutoff) ? 1.0 : 0.0);

  float internal_edge = 0.0;
  if (outline_internal_edges && max_color_diff >= outline_internal_threshold) {
    internal_edge = (outline_smoothness > 0.0)
      ? smoothstep(outline_internal_threshold - soft, outline_internal_threshold + soft, max_color_diff)
      : 1.0;
  }

  float stroke_factor = 0.0;
  float out_alpha = base_alpha;

  if (outline_mode == 0) {
    // Outer only: draw only outside the original silhouette
    if (base_alpha <= 0.0 && is_dilated > 0.0) {
      stroke_factor = 1.0;
      out_alpha = outline_color.a;
    }
  } else if (outline_mode == 1) {
    // Inner only: draw inside the original silhouette where eroded_interior < 1.0
    if (base_alpha > 0.0) {
      stroke_factor = max(1.0 - eroded_interior, internal_edge);
    }
  } else {
    // Mode 2: Center (Hide Edge) - straddles both outside and inside of the contour
    if (is_dilated > 0.0) {
      stroke_factor = max(1.0 - eroded_interior, internal_edge);
      out_alpha = (base_alpha > 0.0) ? max(base_alpha, outline_color.a * stroke_factor) : (outline_color.a * (hard_edges ? 1.0 : stroke_factor));
    }
  }

  return vec4(clamp(stroke_factor, 0.0, 1.0), out_alpha, contour_grad.x, contour_grad.y);
}

void fragment() {
  int cols = max(hframes, 1);
  int rows = max(vframes, 1);
  vec2 grid = vec2(float(cols), float(rows));
  int clamped_frame = clamp(frame, 0, cols * rows - 1);
  vec2 frame_coords = vec2(float(clamped_frame % cols), float(clamped_frame / cols));
  vec2 cell_uv_min = frame_coords / grid;
  vec2 cell_uv_max = (frame_coords + vec2(1.0)) / grid;

  // Automatically wrap tiled UVs on 3D meshes whose UVs extend outside [0, 1], or when tile_base_texture is enabled
  bool is_tiled_uv = tile_base_texture || (UV.x < 0.0 || UV.x > 1.0 || UV.y < 0.0 || UV.y > 1.0);
  vec2 local_uv = is_tiled_uv ? fract(UV) : UV;
  vec2 base_uv = mix(cell_uv_min, cell_uv_max, local_uv);

  vec2 duv_dx = dFdx(base_uv);
  vec2 duv_dy = dFdy(base_uv);

  vec4 raw_base_col = use_base_texture ? texture(base_texture, base_uv) : vec4(get_target_rgb(replace_mode, replace_color, vec3(1.0)), 1.0);
  float base_alpha = evaluate_base_alpha(raw_base_col.a);
  vec3 snapped_rgb = evaluate_base_rgb(raw_base_col.rgb);
  vec4 base_col = vec4(snapped_rgb, max(base_alpha, (outline_enabled && outline_mode == 2) ? 1.0 : 0.0));
  vec4 final_col = vec4(snapped_rgb, base_alpha);

  vec4 outline_res = evaluate_outline_stroke(base_uv, cell_uv_min, cell_uv_max, is_tiled_uv, raw_base_col, base_alpha, duv_dx, duv_dy, TIME);
  float stroke_factor = outline_res.x;
  float out_alpha = outline_res.y;
  vec2 contour_grad = outline_res.zw;

  // Evaluate 2.5D Offset Drop Shadow when enabled
  float shadow_alpha = 0.0;
  if (shadow_enabled && use_base_texture && out_alpha < 1.0) {
    vec2 shadow_uv = base_uv - compute_outline_uv_offset(shadow_offset, duv_dx, duv_dy);
    vec2 cell_span = max(cell_uv_max - cell_uv_min, vec2(0.00001));
    bool sh_oob = (!is_tiled_uv) && (shadow_uv.x < cell_uv_min.x || shadow_uv.x > cell_uv_max.x || shadow_uv.y < cell_uv_min.y || shadow_uv.y > cell_uv_max.y);
    vec2 eff_sh_uv = is_tiled_uv ? (cell_uv_min + fract((shadow_uv - cell_uv_min) / cell_span) * cell_span) : shadow_uv;
    vec4 sh_col = sh_oob ? vec4(0.0) : textureLod(base_texture, eff_sh_uv, 0.0);
    if (!sh_oob && evaluate_base_alpha(sh_col.a) > 0.0) {
      shadow_alpha = shadow_color.a;
    }
  }

  float combined_silhouette_alpha = max(out_alpha, shadow_alpha);
  if (combined_silhouette_alpha <= 0.0) {
    discard;
  }

  bool need_bayer = dither_enabled || opacity_dither_enabled || dissolve_amount > 0.0;
  float bayer_val = need_bayer ? eval_bayer4x4(SCREEN_UV * VIEWPORT_SIZE) : 0.5;
  vec2 p_uv = compute_pattern_uv_full(
    UV, v_local_pos, v_local_normal, v_world_pos, v_world_normal,
    VERTEX, v_node_view_center, SCREEN_UV, VIEWPORT_SIZE, TIME
  );
  vec4 pat = textureLod(custom_pattern, p_uv, 0.0);

  // Check Pattern-Driven Dissolve before shading
  float dissolve_rim = 0.0;
  if (dissolve_amount > 0.0) {
    float pat_luma = dot(pat.rgb, vec3(0.299, 0.587, 0.114));
    float dissolve_noise = mix(pat_luma, bayer_val, 0.5);
    float threshold_val = dissolve_amount * 1.05;
    if (dissolve_noise < threshold_val - dissolve_edge_width) {
      discard;
    } else if (dissolve_noise < threshold_val) {
      dissolve_rim = 1.0;
    }
  }

  // Evaluate 3D Fresnel Rim if enabled
  float fresnel_factor = 0.0;
  if (fresnel_enabled) {
    float ndotv = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
    fresnel_factor = pow(1.0 - ndotv, fresnel_power);
    if (dither_enabled) {
      fresnel_factor = step(bayer_val, fresnel_factor);
    }
  }

  bool eff_invert = invert_pattern;
  if (fresnel_enabled && fresnel_invert_pattern && fresnel_factor > 0.5) {
    eff_invert = !eff_invert;
  }

  float interior_alpha = base_alpha;

  // Evaluate pattern replacement whenever the pixel is visible inside the main shape
  if (base_alpha > 0.0 || (outline_enabled && outline_mode == 2 && stroke_factor < 1.0)) {
    if (hard_edges && distance(raw_base_col.rgb, snapped_rgb) > 0.12) {
      float m = compute_replace_mask(base_col, replace_mode, replace_color, threshold);
      if (m <= 0.0 && replace_mode != 3) {
        vec3 target_rgb = get_target_rgb(replace_mode, replace_color, raw_base_col.rgb);
        if (distance(raw_base_col.rgb, target_rgb) < 0.9) {
          base_col.rgb = target_rgb;
          final_col.rgb = target_rgb;
        }
      }
    }

    float mask = compute_replace_mask(base_col, replace_mode, replace_color, threshold);

    // Optional Duotone / Unreplaced Base Color Remap
    if (remap_unreplaced && mask < 1.0) {
      vec4 unrep_col = unreplaced_color;
      if (unreplaced_use_pattern) {
        unrep_col = evaluate_pattern_color(pat, unreplaced_color, bg_color, !eff_invert, bayer_val);
      }
      final_col.rgb = mix(unrep_col.rgb, final_col.rgb, mask);
      if (pattern_alpha_affects_surface) {
        interior_alpha = mix(base_alpha * unrep_col.a, interior_alpha, mask);
      }
    }

    if (mask > 0.0) {
      vec4 col = evaluate_pattern_color(pat, fg_color, bg_color, eff_invert, bayer_val);
      float pat_eff_alpha = clamp(col.a * pattern_opacity, 0.0, 1.0);
      vec3 blended_rgb = apply_pattern_blend(final_col.rgb, col.rgb, pattern_blend_mode);
      if (pattern_alpha_affects_surface) {
        final_col.rgb = mix(final_col.rgb, blended_rgb, mask);
        interior_alpha = mix(interior_alpha, base_alpha * pat_eff_alpha, mask);
      } else {
        final_col.rgb = mix(final_col.rgb, blended_rgb, mask * pat_eff_alpha);
      }
    }

    // Apply Win98 / Sticker Inner Bevel & Emboss using the free 16-direction contour normal
    if (bevel_enabled && length(contour_grad) > 0.001) {
      vec2 c_norm = normalize(contour_grad);
      vec2 light_dir = vec2(cos(bevel_angle), -sin(bevel_angle));
      float b_dot = dot(c_norm, light_dir);
      float edge_band = clamp(length(contour_grad) * 0.25, 0.0, 1.0);
      if (dither_enabled) {
        edge_band = step(bayer_val, edge_band);
      }
      if (b_dot >= 0.0) {
        final_col.rgb = mix(final_col.rgb, bevel_light_color.rgb, b_dot * edge_band * bevel_strength * bevel_light_color.a);
      } else {
        final_col.rgb = mix(final_col.rgb, bevel_shadow_color.rgb, (-b_dot) * edge_band * bevel_strength * bevel_shadow_color.a);
      }
    }

    // Apply 3D Fresnel color tint when not purely inverting the pattern
    if (fresnel_enabled && !fresnel_invert_pattern && fresnel_factor > 0.0) {
      final_col.rgb = mix(final_col.rgb, fresnel_color.rgb, fresnel_factor * fresnel_color.a);
    }
  }

  // Compute effective interior & stroke opacity
  float eff_interior_alpha = interior_alpha * master_opacity;
  vec4 stroke_col = outline_color;
  if (stroke_factor > 0.0) {
    if (outline_color_mode == 1) {
      stroke_col = evaluate_pattern_color(pat, fg_color, bg_color, !eff_invert, bayer_val);
    } else if (outline_color_mode == 2) {
      float t = get_effective_time(TIME);
      float dash = step(0.0, sin((p_uv.x + p_uv.y) * 24.0 + t * 8.0));
      stroke_col = mix(bg_color, fg_color, dash);
    }
    final_col.rgb = mix(final_col.rgb, stroke_col.rgb, stroke_factor * stroke_col.a);
  }

  float eff_stroke_alpha = stroke_col.a * (outline_ignores_master_opacity ? 1.0 : master_opacity);
  float shape_alpha = eff_interior_alpha;
  if (outline_enabled && outline_width > 0.0 && stroke_factor > 0.0) {
    if (outline_mode == 0) {
      shape_alpha = (base_alpha > 0.0) ? eff_interior_alpha : (stroke_factor * eff_stroke_alpha);
    } else {
      shape_alpha = mix(eff_interior_alpha, eff_stroke_alpha, stroke_factor);
    }
  }

  float eff_shadow_alpha = shadow_alpha * master_opacity;
  if (eff_shadow_alpha > 0.0 && shape_alpha < 1.0) {
    final_col.rgb = mix(shadow_color.rgb, final_col.rgb, shape_alpha);
  }

  float combined_alpha = clamp(max(shape_alpha, eff_shadow_alpha), 0.0, 1.0);

  // Apply Dissolve Edge Rim Color
  if (dissolve_rim > 0.0) {
    final_col.rgb = mix(final_col.rgb, dissolve_edge_color.rgb, dissolve_edge_color.a);
  }

  // Apply CRT / 90s Scanline Modulation
  if (scanline_strength > 0.0) {
    float scan = 0.5 + 0.5 * sin(SCREEN_UV.y * scanline_density * 6.28318);
    final_col.rgb *= mix(1.0, scan, scanline_strength);
  }

  // Evaluate Screen-Space Backdrop Effects (Refraction, Pixelation, Blur, Chromatic Split, Backdrop Blend Modes)
  bool use_backdrop = (backdrop_blend_mode != 0)
    || (abs(backdrop_refraction) > 0.0001)
    || (backdrop_pixel_size > 1.0)
    || (backdrop_blur_lod > 0.0)
    || (backdrop_chromatic_aberration > 0.0001);

  if (use_backdrop && combined_alpha > alpha_scissor_threshold) {
    vec2 bg_uv = SCREEN_UV;
    if (backdrop_pixel_size > 1.0) {
      vec2 vp = max(VIEWPORT_SIZE, vec2(1.0));
      vec2 grid_sz = max(vp / backdrop_pixel_size, vec2(1.0));
      bg_uv = (floor(bg_uv * grid_sz) + vec2(0.5)) / grid_sz;
    }

    float pat_bw_raw = dot(pat.rgb, vec3(0.299, 0.587, 0.114));
    vec2 pat_warp = vec2(cos(p_uv.y * 6.28318), sin(p_uv.x * 6.28318)) * (pat_bw_raw * 2.0 - 1.0);
    vec2 bevel_warp = (length(contour_grad) > 0.001) ? normalize(contour_grad) : vec2(0.0);

    if (abs(backdrop_refraction) > 0.0001) {
      vec2 refract_ofs = (pat_warp * 0.04 + bevel_warp * 0.03) * backdrop_refraction;
      bg_uv = clamp(bg_uv + refract_ofs, vec2(0.001), vec2(0.999));
    }

    vec3 backdrop_rgb;
    if (backdrop_chromatic_aberration > 0.0001) {
      vec2 ca_dir = normalize(pat_warp + bevel_warp + vec2(0.0001, 0.0));
      vec2 ca_ofs = ca_dir * backdrop_chromatic_aberration;
      backdrop_rgb.r = textureLod(screen_texture, clamp(bg_uv + ca_ofs, vec2(0.001), vec2(0.999)), backdrop_blur_lod).r;
      backdrop_rgb.g = textureLod(screen_texture, bg_uv, backdrop_blur_lod).g;
      backdrop_rgb.b = textureLod(screen_texture, clamp(bg_uv - ca_ofs, vec2(0.001), vec2(0.999)), backdrop_blur_lod).b;
    } else {
      backdrop_rgb = textureLod(screen_texture, bg_uv, backdrop_blur_lod).rgb;
    }

    vec3 filtered_bg = final_col.rgb;
    if (backdrop_blend_mode == 1) {
      // Multiply (Stained Glass)
      filtered_bg = backdrop_rgb * final_col.rgb;
    } else if (backdrop_blend_mode == 2) {
      // Screen / Add (Hologram Glow)
      filtered_bg = vec3(1.0) - (vec3(1.0) - backdrop_rgb) * (vec3(1.0) - final_col.rgb);
    } else if (backdrop_blend_mode == 3) {
      // Overlay (Contrast Tint)
      filtered_bg = apply_pattern_blend(backdrop_rgb, final_col.rgb, 3);
    } else if (backdrop_blend_mode == 4) {
      // Difference / Invert (X-Ray Negative)
      filtered_bg = vec3(1.0) - backdrop_rgb;
    } else if (backdrop_blend_mode == 5) {
      // Duotone Palette Lens: maps background scene luminance to bg_color -> fg_color
      float bg_luma = dot(backdrop_rgb, vec3(0.299, 0.587, 0.114));
      if (dither_enabled) {
        bg_luma = clamp(bg_luma + (bayer_val - 0.5) * dither_strength, 0.0, 1.0);
      }
      if (hard_edges) {
        bg_luma = step(0.5, bg_luma);
      }
      filtered_bg = mix(bg_color.rgb, fg_color.rgb, bg_luma);
    } else if (backdrop_blend_mode == 6) {
      // Pattern Mask Invert: inverts background where the pattern is white (or black if inverted)
      float p_step = step(0.5, eff_invert ? (1.0 - pat_bw_raw) : pat_bw_raw);
      filtered_bg = mix(backdrop_rgb * bg_color.rgb, vec3(1.0) - backdrop_rgb, p_step);
    }

    // Preserve solid outline stroke on top of filtered backdrop if active
    if (stroke_factor > 0.0) {
      filtered_bg = mix(filtered_bg, stroke_col.rgb, stroke_factor * stroke_col.a);
    }

    final_col.rgb = mix(backdrop_rgb, filtered_bg, combined_alpha);
    combined_alpha = 1.0;
  }

  // Optional 90s Screen-Door Dithered Transparency
  if (opacity_dither_enabled && combined_alpha < 1.0) {
    if (combined_alpha <= bayer_val) {
      discard;
    }
    combined_alpha = 1.0;
  }

  if (combined_alpha <= alpha_scissor_threshold) {
    discard;
  }

  ALBEDO = final_col.rgb * (1.0 + emission_strength);
  ALPHA = combined_alpha;
}
