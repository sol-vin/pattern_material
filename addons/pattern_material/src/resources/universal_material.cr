require "lapis"
require "./spritesheets"
require "./patterns"
require "./palette"

include Godot

# Ergonomic wrapper and fluent builder around a `ShaderMaterial` backed by
# `res://addons/pattern_material/shaders/pattern_replace.gdshader`.
#
# Combines `Faces`, `Glyphs`, `SpritesheetAtlas`, `Patterns`, `PatternGenerator`, and `Palette`
# with typed helper methods for configuring projection modes, transforms, wave motions,
# outlines, bevels, 3D cel shading, drop shadows, retro dithering, dissolve wipes,
# backdrop refraction, and vertex effects.
class UniversalMaterial
  SHADER_PATH        = "res://addons/pattern_material/shaders/pattern_replace.gdshader"
  LEGACY_SHADER_PATH = "res://shaders/pattern_replace.gdshader"

  alias ParamValue = Bool | Int64 | Float64 | String | Color | Vector2 | Vector3

  enum ProjectionMode
    Camera         = 0
    ModelNormals   = 1
    WorldTriplanar = 2
    MeshUV         = 3
    Cylindrical    = 4
    Spherical      = 5
  end

  enum ReplaceMode
    R           = 0
    G           = 1
    B           = 2
    A           = 3
    White       = 4
    CustomColor = 5
  end

  enum OutlineMode
    Outer  = 0
    Inner  = 1
    Center = 2
  end

  enum OutlineColorMode
    SolidColor      = 0
    InvertedPattern = 1
    AlternatingDash = 2
  end

  enum BlendMode
    Replace    = 0
    Multiply   = 1
    Screen     = 2
    Overlay    = 3
    Add        = 4
    Difference = 5
  end

  enum PositionWaveMode
    None             = 0
    Sin              = 1
    Cos              = 2
    CircularOrbit    = 3
    PingPongTriangle = 4
  end

  enum RotationWaveMode
    None             = 0
    Sin              = 1
    Cos              = 2
    PingPongTriangle = 3
  end

  enum ScaleWaveMode
    None             = 0
    Sin              = 1
    Cos              = 2
    AbsSinBounce     = 3
    PingPongTriangle = 4
  end

  enum RippleMode
    CrossWave    = 0
    LiquidShear  = 1
    RadialRipple = 2
  end

  enum BillboardMode
    Disabled   = 0
    Full       = 1
    YBillboard = 2
  end

  enum VertexMotionMode
    Disabled       = 0
    SurfaceWaves3D = 1
    PaperSway25D   = 2
    Breathing      = 3
  end

  enum BackdropBlendMode
    StandardAlpha     = 0
    Multiply          = 1
    Screen            = 2
    Overlay           = 3
    InvertXRay        = 4
    DuotonePaletteMap = 5
    PatternMaskInvert = 6
  end

  getter material : ShaderMaterial
  getter parameters : Hash(String, ParamValue)
  getter generator : PatternGenerator? = nil

  def initialize(@material : ShaderMaterial = ShaderMaterial.new)
    @parameters = Hash(String, ParamValue).new
    ensure_shader!
  end

  # Ensures `pattern_replace.gdshader` is assigned to the underlying `ShaderMaterial` when running in Godot.
  def ensure_shader! : self
    if !@material.pointer.null?
      current = @material.get_shader
      if current.pointer.null?
        if sh = Godot.preload?(SHADER_PATH, Shader)
          @material.set_shader(sh) if !sh.pointer.null?
        end
      end
    end
    self
  rescue
    self
  end

  # Sets a shader parameter on both the underlying Godot `ShaderMaterial` (when active)
  # and the local parameter mirror for inspection/testing.
  def set_param(name : String, value : ParamValue) : self
    @parameters[name] = value
    if !@material.pointer.null?
      @material.call("set_shader_parameter", name, value)
    end
    self
  end

  def get_param?(name : String) : ParamValue?
    @parameters[name]?
  end

  # Configures the material to display an icon cell from any `SpritesheetAtlas`.
  def set_atlas(atlas : SpritesheetAtlas, key : String | Char | Symbol) : self
    idx = atlas.apply_to(@material, key)
    @parameters["base_texture"] = atlas.texture_path
    @parameters["hframes"] = atlas.hframes.to_i64
    @parameters["vframes"] = atlas.vframes.to_i64
    @parameters["frame"] = idx.to_i64
    self
  end

  # Configures the material to display a face icon from `Faces` (`res://textures/fontawesome/faces.svg`).
  def set_face(key : String | Char | Symbol) : self
    idx = Faces.apply_to(@material, key)
    @parameters["base_texture"] = Faces.texture_path
    @parameters["hframes"] = Faces.hframes.to_i64
    @parameters["vframes"] = Faces.vframes.to_i64
    @parameters["frame"] = idx.to_i64
    self
  end

  # Configures the material to display a badge glyph from `Glyphs` (`res://textures/fontawesome/letter_glyphs.svg`).
  def set_glyph(key : String | Char | Symbol) : self
    idx = Glyphs.apply_to(@material, key)
    @parameters["base_texture"] = Glyphs.texture_path
    @parameters["hframes"] = Glyphs.hframes.to_i64
    @parameters["vframes"] = Glyphs.vframes.to_i64
    @parameters["frame"] = idx.to_i64
    self
  end

  # Assigns `custom_pattern` from `Patterns` (`res://addons/pattern_material/textures/patterns/*.svg`).
  def set_pattern(key : String | Symbol) : self
    res_path = Patterns.apply_to(@material, key)
    @generator = nil
    @parameters["custom_pattern"] = res_path
    self
  end

  # Assigns a procedural `PatternGenerator` to `custom_pattern`.
  def set_pattern(gen : PatternGenerator) : self
    set_generator(gen)
  end

  # Assigns a procedural `PatternGenerator` to `custom_pattern` on the material.
  def set_generator(gen : PatternGenerator) : self
    Patterns.apply_to(@material, gen)
    @generator = gen
    @parameters["custom_pattern"] = gen.class.name
    self
  end

  # Configures `fg_color`, `bg_color`, and optional `outline_color` / `unreplaced_color` using `Palette` indices, names, or `Color`s.
  def set_colors(
    fg : Palette::ColorId | Int | String | Symbol | Color,
    bg : Palette::ColorId | Int | String | Symbol | Color,
    outline : (Palette::ColorId | Int | String | Symbol | Color)? = nil,
    unreplaced : (Palette::ColorId | Int | String | Symbol | Color)? = nil
  ) : self
    fg_col = Palette.resolve(fg)
    bg_col = Palette.resolve(bg)
    set_param("fg_color", fg_col)
    set_param("bg_color", bg_col)
    if out_col = outline
      set_param("outline_color", Palette.resolve(out_col))
    end
    if unrep = unreplaced
      set_param("remap_unreplaced", true)
      set_param("unreplaced_color", Palette.resolve(unrep))
    end
    self
  end

  # Applies a curated `Palette::Theme` (setting `fg_color`, `bg_color`, `outline_color`, `unreplaced_color`, and optional `mid_color`).
  def set_theme(
    theme : Palette::Theme | String | Symbol,
    use_tritone : Bool = false
  ) : self
    tc = Palette.theme(theme)
    set_colors(fg: tc.fg, bg: tc.bg, outline: tc.outline, unreplaced: tc.unreplaced)
    set_tritone(mid: tc.mid, enabled: use_tritone)
    self
  end

  # Configures the 3-color tritone palette ramp (`bg_color -> mid_color -> fg_color`).
  def set_tritone(
    mid : Palette::ColorId | Int | String | Symbol | Color,
    mid_point : Float64 = 0.5,
    enabled : Bool = true
  ) : self
    set_param("use_mid_color", enabled)
    set_param("mid_color", Palette.resolve(mid))
    set_param("mid_point", mid_point)
    self
  end

  # Configures which channel or target color is replaced by the pattern, plus hard-edge contour snapping.
  def set_replace_mask(
    mode : ReplaceMode = ReplaceMode::G,
    color : Palette::ColorId | Int | String | Symbol | Color = "white",
    threshold : Float64 = 0.5,
    hard_edges : Bool = true,
    hard_edge_threshold : Float64 = 0.5
  ) : self
    set_param("replace_mode", mode.value.to_i64)
    set_param("replace_color", Palette.resolve(color))
    set_param("threshold", threshold)
    set_param("hard_edges", hard_edges)
    set_param("hard_edge_threshold", hard_edge_threshold)
    self
  end

  # Configures pattern compositing blend mode, opacity, and black/white inversion.
  def set_pattern_blend(
    mode : BlendMode = BlendMode::Replace,
    opacity : Float64 = 1.0,
    invert : Bool = false
  ) : self
    set_param("pattern_blend_mode", mode.value.to_i64)
    set_param("pattern_opacity", opacity)
    set_param("invert_pattern", invert)
    self
  end

  # Configures 3D surface mode (enables `tile_base_texture` or disables `use_base_texture` for pure pattern brushes).
  def set_3d_surface(
    projection : ProjectionMode = ProjectionMode::WorldTriplanar,
    use_base_texture : Bool = false,
    tile_base_texture : Bool = true
  ) : self
    set_param("perspective_normals", projection.value.to_i64)
    set_param("use_base_texture", use_base_texture)
    set_param("tile_base_texture", tile_base_texture)
    self
  end

  # Configures static UV transform, tiling scale, rotation, mirroring, and N-fold kaleidoscope symmetry.
  def set_transform(
    scale : Float64 = 1.0,
    non_uniform_scale : Vector2 = Vector2.new(1.0_f32, 1.0_f32),
    offset : Vector2 = Vector2.new(0.0_f32, 0.0_f32),
    rotation : Float64 = 0.0,
    flip_x : Bool = false,
    flip_y : Bool = false,
    mirror_tiles : Bool = false,
    scaling : Bool = true,
    kaleidoscope_segments : Int = 0
  ) : self
    set_param("scale_factor_mult", scale)
    set_param("non_uniform_scale", non_uniform_scale)
    set_param("static_offset", offset)
    set_param("static_rotation", rotation)
    set_param("flip_x", flip_x)
    set_param("flip_y", flip_y)
    set_param("mirror_tiles", mirror_tiles)
    set_param("scaling", scaling)
    set_param("kaleidoscope_segments", kaleidoscope_segments.to_i64)
    self
  end

  # Configures linear UV drift speed and periodic wave oscillation for pattern position.
  def set_position_motion(
    linear_speed : Vector2 = Vector2.new(0.0_f32, 0.0_f32),
    wave_mode : PositionWaveMode = PositionWaveMode::None,
    wave_amp : Vector2 = Vector2.new(0.25_f32, 0.25_f32),
    wave_freq : Vector2 = Vector2.new(1.0_f32, 1.0_f32),
    wave_phase : Vector2 = Vector2.new(0.0_f32, 0.0_f32)
  ) : self
    set_param("pos_time_mult", linear_speed)
    set_param("pos_wave_mode", wave_mode.value.to_i64)
    set_param("pos_wave_amp", wave_amp)
    set_param("pos_wave_freq", wave_freq)
    set_param("pos_wave_phase", wave_phase)
    self
  end

  # Configures continuous angular spin and periodic pendulum wave swing for pattern rotation.
  def set_rotation_motion(
    linear_speed : Float64 = 0.0,
    wave_mode : RotationWaveMode = RotationWaveMode::None,
    wave_amp : Float64 = 0.5,
    wave_freq : Float64 = 1.0
  ) : self
    set_param("rot_time_mult", linear_speed)
    set_param("rot_wave_mode", wave_mode.value.to_i64)
    set_param("rot_wave_amp", wave_amp)
    set_param("rot_wave_freq", wave_freq)
    self
  end

  # Configures periodic breathing/pulsing oscillation for pattern scale.
  def set_scale_pulse(
    wave_mode : ScaleWaveMode = ScaleWaveMode::None,
    wave_amp : Vector2 = Vector2.new(0.25_f32, 0.25_f32),
    wave_freq : Vector2 = Vector2.new(1.0_f32, 1.0_f32)
  ) : self
    set_param("scale_wave_mode", wave_mode.value.to_i64)
    set_param("scale_wave_amp", wave_amp)
    set_param("scale_wave_freq", wave_freq)
    self
  end

  # Configures spatial UV wave/ripple distortion across the pattern.
  def set_ripple(
    enabled : Bool = true,
    mode : RippleMode = RippleMode::CrossWave,
    amp : Vector2 = Vector2.new(0.05_f32, 0.05_f32),
    freq : Vector2 = Vector2.new(6.0_f32, 6.0_f32),
    speed : Vector2 = Vector2.new(2.0_f32, 2.0_f32)
  ) : self
    set_param("ripple_enabled", enabled)
    set_param("ripple_mode", mode.value.to_i64)
    set_param("ripple_amp", amp)
    set_param("ripple_freq", freq)
    set_param("ripple_speed", speed)
    self
  end

  # Configures choppy 90s / stop-motion FPS time quantization.
  def set_time_quantization(
    enabled : Bool = true,
    fps : Float64 = 12.0
  ) : self
    set_param("quantize_time", enabled)
    set_param("time_fps", fps)
    self
  end

  # Configures outline stroke parameters including optional boiling lines and outline color mode.
  def set_outline(
    enabled : Bool = true,
    width : Float64 = 3.0,
    mode : OutlineMode = OutlineMode::Center,
    color_mode : OutlineColorMode = OutlineColorMode::SolidColor,
    boil_amp : Float64 = 0.0,
    boil_freq : Float64 = 8.0
  ) : self
    set_param("outline_enabled", enabled)
    set_param("outline_width", width)
    set_param("outline_mode", mode.value.to_i64)
    set_param("outline_color_mode", color_mode.value.to_i64)
    set_param("outline_boil_amp", boil_amp)
    set_param("outline_boil_freq", boil_freq)
    self
  end

  # Configures Win98 / sticker inner bevel & emboss lighting.
  def set_bevel(
    enabled : Bool = true,
    strength : Float64 = 0.5,
    angle : Float64 = 2.356
  ) : self
    set_param("bevel_enabled", enabled)
    set_param("bevel_strength", strength)
    set_param("bevel_angle", angle)
    self
  end

  # Configures 3D Fresnel rim highlighting / pattern inversion.
  def set_fresnel(
    enabled : Bool = true,
    power : Float64 = 2.5,
    invert_pattern : Bool = false,
    color : (Palette::ColorId | Int | String | Symbol | Color)? = nil
  ) : self
    set_param("fresnel_enabled", enabled)
    set_param("fresnel_power", power)
    set_param("fresnel_invert_pattern", invert_pattern)
    if c = color
      set_param("fresnel_color", Palette.resolve(c))
    end
    self
  end

  # Configures 3D directional Cel / Bayer-dithered toon lighting.
  def set_cel_shading(
    enabled : Bool = true,
    strength : Float64 = 0.35,
    bands : Int = 2,
    dither_light : Bool = false,
    light_dir : Vector3 = Vector3.new(0.4_f32, 0.8_f32, 0.5_f32)
  ) : self
    set_param("cel_shade_enabled", enabled)
    set_param("cel_shade_strength", strength)
    set_param("cel_bands", bands.to_i64)
    set_param("cel_dither_light", dither_light)
    set_param("cel_light_dir", light_dir)
    self
  end

  # Configures the 2.5D offset paper-cutout drop shadow (with optional Bayer dither or pattern hatch).
  def set_drop_shadow(
    enabled : Bool = true,
    offset : Vector2 = Vector2.new(4.0_f32, -4.0_f32),
    color : Palette::ColorId | Int | String | Symbol | Color = "deep_indigo",
    dither : Bool = false,
    use_pattern : Bool = false
  ) : self
    set_param("shadow_enabled", enabled)
    set_param("shadow_offset", offset)
    set_param("shadow_color", Palette.resolve(color))
    set_param("shadow_dither", dither)
    set_param("shadow_use_pattern", use_pattern)
    self
  end

  # Configures 4x4 Bayer matrix dithering.
  def set_dither(
    enabled : Bool = true,
    strength : Float64 = 0.5,
    pixel_size : Float64 = 2.0
  ) : self
    set_param("dither_enabled", enabled)
    set_param("dither_strength", strength)
    set_param("dither_pixel_size", pixel_size)
    self
  end

  # Configures pattern-driven dissolve wipe.
  def set_dissolve(
    amount : Float64,
    edge_width : Float64 = 0.05,
    edge_color : Palette::ColorId | Int | String | Symbol | Color = "white"
  ) : self
    set_param("dissolve_amount", amount)
    set_param("dissolve_edge_width", edge_width)
    set_param("dissolve_edge_color", Palette.resolve(edge_color))
    self
  end

  # Configures VHS glitch and CRT scanlines.
  def set_retro_crt(
    glitch_intensity : Float64 = 0.25,
    scanline_strength : Float64 = 0.3,
    scanline_density : Float64 = 120.0,
    emission_strength : Float64 = 1.0
  ) : self
    set_param("glitch_intensity", glitch_intensity)
    set_param("scanline_strength", scanline_strength)
    set_param("scanline_density", scanline_density)
    set_param("emission_strength", emission_strength)
    self
  end

  # Configures surface pixelation and prismatic RGB channel split on the pattern itself.
  def set_surface_fx(
    pixel_size : Float64 = 1.0,
    chromatic_split : Float64 = 0.0
  ) : self
    set_param("surface_pixel_size", pixel_size)
    set_param("surface_chromatic_split", chromatic_split)
    self
  end

  # Configures surface transparency, per-region cutout/translucency, and 90s screen-door dithered opacity.
  def set_transparency(
    master_opacity : Float64 = 1.0,
    pattern_alpha_affects_surface : Bool = true,
    outline_ignores_master_opacity : Bool = false,
    opacity_dither_enabled : Bool = false,
    alpha_scissor_threshold : Float64 = 0.001
  ) : self
    set_param("master_opacity", master_opacity)
    set_param("pattern_alpha_affects_surface", pattern_alpha_affects_surface)
    set_param("outline_ignores_master_opacity", outline_ignores_master_opacity)
    set_param("opacity_dither_enabled", opacity_dither_enabled)
    set_param("alpha_scissor_threshold", alpha_scissor_threshold)
    self
  end

  # Configures screen-space backdrop effects (refraction, pixelation, frosted blur, chromatic split, and backdrop blend modes).
  def set_backdrop_fx(
    blend_mode : BackdropBlendMode = BackdropBlendMode::StandardAlpha,
    refraction : Float64 = 0.0,
    pixel_size : Float64 = 1.0,
    blur_lod : Float64 = 0.0,
    chromatic_aberration : Float64 = 0.0
  ) : self
    set_param("backdrop_blend_mode", blend_mode.value.to_i64)
    set_param("backdrop_refraction", refraction)
    set_param("backdrop_pixel_size", pixel_size)
    set_param("backdrop_blur_lod", blur_lod)
    set_param("backdrop_chromatic_aberration", chromatic_aberration)
    self
  end

  # Configures vertex billboarding, 3D surface waves, or paper cutout sway.
  def set_vertex_fx(
    billboard : BillboardMode = BillboardMode::Disabled,
    motion : VertexMotionMode = VertexMotionMode::Disabled,
    wave_amp : Vector2 = Vector2.new(0.08_f32, 0.08_f32),
    wave_freq : Vector2 = Vector2.new(2.0_f32, 2.0_f32),
    wave_speed : Float64 = 2.0,
    vertex_snap : Bool = false,
    snap_resolution : Float64 = 160.0
  ) : self
    set_param("billboard_mode", billboard.value.to_i64)
    set_param("vertex_motion_mode", motion.value.to_i64)
    set_param("vertex_wave_amp", wave_amp)
    set_param("vertex_wave_freq", wave_freq)
    set_param("vertex_wave_speed", wave_speed)
    set_param("vertex_snap_enabled", vertex_snap)
    set_param("vertex_snap_resolution", snap_resolution)
    self
  end

  # Copies all configured shader parameters onto another `ShaderMaterial`.
  def apply_to(target_mat : ShaderMaterial) : self
    return self if target_mat.pointer.null?
    @parameters.each do |k, v|
      next if k == "custom_pattern" || k == "base_texture"
      target_mat.call("set_shader_parameter", k, v)
    end
    if gen = @generator
      gen.apply_to(target_mat)
    elsif pat_key = @parameters["custom_pattern"]?.try(&.as?(String))
      Patterns.apply_to(target_mat, pat_key) if Patterns.has?(pat_key)
    end
    self
  end

  # Assigns the underlying `ShaderMaterial` onto a `GeometryInstance3D` (`material_override`),
  # `CSGShape3D` / `CanvasItem` (`material`), or `MeshInstance3D` mesh surface.
  def apply_to(target_node : Node) : self
    ensure_shader!
    return self if target_node.pointer.null? || @material.pointer.null?
    if target_node.responds_to?(:material_override=)
      target_node.call("set_material_override", @material)
    elsif target_node.has_method("set_material_override")
      target_node.call("set_material_override", @material)
    elsif target_node.has_method("set_material")
      target_node.call("set_material", @material)
    end
    self
  rescue
    self
  end

  # Serializes this `UniversalMaterial` configuration to a Godot 4 `.tres` `ShaderMaterial` string.
  def to_tres : String
    pat_path = @parameters["custom_pattern"]?.try(&.as?(String))
    has_pat_ext = pat_path && pat_path.starts_with?("res://")

    String.build do |io|
      io << %([gd_resource type="ShaderMaterial" format=3]\n\n)
      io << %([ext_resource type="Shader" path="#{SHADER_PATH}" id="1_shader"]\n)
      if has_pat_ext
        io << %([ext_resource type="Texture2D" path="#{pat_path}" id="2_pat"]\n)
      end
      io << %(\n[resource]\n)
      io << %(render_priority = 0\n)
      io << %(shader = ExtResource("1_shader")\n)
      if has_pat_ext
        io << %(shader_parameter/custom_pattern = ExtResource("2_pat")\n)
      end
      @parameters.keys.sort!.each do |k|
        next if k == "custom_pattern" || k == "base_texture"
        v = @parameters[k]
        io << "shader_parameter/#{k} = #{format_tres_value(v)}\n"
      end
    end
  end

  # Writes `to_tres` to `path` on disk and returns the resolved filesystem path.
  def save_tres(path : String) : String
    target = path.strip
    raise ArgumentError.new("Material .tres path cannot be empty") if target.empty?
    resolved = target.sub(/^res:\/\//, "")
    dir = File.dirname(resolved)
    Dir.mkdir_p(dir) unless Dir.exists?(dir)
    File.write(resolved, to_tres)
    resolved
  end

  # Preset factory: 2.5D animated cutout character style.
  def self.cutout_character : UniversalMaterial
    new
      .set_pattern("moroccan")
      .set_theme(Palette::Theme::WatermelonPunch)
      .set_outline(enabled: true, width: 3.0, mode: OutlineMode::Center, boil_amp: 0.15, boil_freq: 8.0)
      .set_transform(scale: 1.875)
      .set_position_motion(linear_speed: Vector2.new(0.325_f32, 0.0_f32))
      .set_rotation_motion(linear_speed: 0.565, wave_mode: RotationWaveMode::Sin, wave_amp: 0.5, wave_freq: 1.0)
      .set_ripple(enabled: true, mode: RippleMode::LiquidShear, amp: Vector2.new(0.05_f32, 0.05_f32))
      .set_time_quantization(enabled: true, fps: 12.0)
  end

  # Preset factory: embossed enamel pin / sticker glyph badge style.
  def self.sticker_glyph : UniversalMaterial
    new
      .set_pattern("hexagons")
      .set_colors(fg: "peach_sorbet", bg: "salmon_pink", outline: "white", unreplaced: "deep_indigo")
      .set_outline(enabled: true, width: 2.5, mode: OutlineMode::Center)
      .set_bevel(enabled: true, strength: 0.65, angle: 2.356)
      .set_drop_shadow(enabled: true, offset: Vector2.new(3.0_f32, -3.0_f32), color: "deep_indigo")
      .set_transform(scale: 2.0)
      .set_position_motion(linear_speed: Vector2.new(0.15_f32, 0.15_f32))
  end

  # Preset factory: CRT scanline & VHS glitch hologram style.
  def self.retro_hologram : UniversalMaterial
    new
      .set_pattern("circuit_board")
      .set_theme(Palette::Theme::CyberMint)
      .set_outline(enabled: true, width: 4.0, mode: OutlineMode::Center, color_mode: OutlineColorMode::AlternatingDash, boil_amp: 0.2, boil_freq: 12.0)
      .set_fresnel(enabled: true, power: 2.0, color: "ice_aqua")
      .set_transform(scale: 2.5, scaling: false)
      .set_position_motion(linear_speed: Vector2.new(0.0_f32, 0.4_f32))
      .set_ripple(enabled: true, mode: RippleMode::CrossWave, amp: Vector2.new(0.03_f32, 0.03_f32), freq: Vector2.new(8.0_f32, 8.0_f32), speed: Vector2.new(3.0_f32, 3.0_f32))
      .set_time_quantization(enabled: true, fps: 15.0)
      .set_dither(enabled: true, strength: 0.5, pixel_size: 2.0)
      .set_retro_crt(glitch_intensity: 0.25, scanline_strength: 0.35, scanline_density: 140.0, emission_strength: 0.8)
  end

  # Preset factory: refractive duotone frosted glass lens style.
  def self.glass_lens : UniversalMaterial
    new
      .set_pattern("topography")
      .set_theme(Palette::Theme::ArcticLagoon)
      .set_outline(enabled: true, width: 3.5, mode: OutlineMode::Center)
      .set_bevel(enabled: true, strength: 0.7, angle: 2.356)
      .set_fresnel(enabled: true, power: 2.2, color: "ice_aqua")
      .set_transparency(master_opacity: 0.85, pattern_alpha_affects_surface: true, outline_ignores_master_opacity: true)
      .set_backdrop_fx(blend_mode: BackdropBlendMode::DuotonePaletteMap, refraction: 0.35, blur_lod: 1.2, chromatic_aberration: 0.008)
  end

  # Preset factory: 3D animated water caustics with surface waves and refraction.
  def self.water_caustics : UniversalMaterial
    new
      .set_pattern("overcast")
      .set_theme(Palette::Theme::ArcticLagoon, use_tritone: true)
      .set_3d_surface(ProjectionMode::WorldTriplanar, use_base_texture: false, tile_base_texture: true)
      .set_outline(enabled: false)
      .set_fresnel(enabled: true, power: 2.2, color: "white")
      .set_cel_shading(enabled: true, strength: 0.25, bands: 3, dither_light: true)
      .set_transform(scale: 1.5, mirror_tiles: true)
      .set_position_motion(linear_speed: Vector2.new(0.18_f32, 0.12_f32), wave_mode: PositionWaveMode::CircularOrbit, wave_amp: Vector2.new(0.15_f32, 0.15_f32))
      .set_ripple(enabled: true, mode: RippleMode::LiquidShear, amp: Vector2.new(0.06_f32, 0.06_f32), freq: Vector2.new(5.0_f32, 5.0_f32), speed: Vector2.new(2.2_f32, 1.8_f32))
      .set_transparency(master_opacity: 0.88)
      .set_backdrop_fx(blend_mode: BackdropBlendMode::Screen, refraction: 0.25, chromatic_aberration: 0.004)
      .set_vertex_fx(motion: VertexMotionMode::SurfaceWaves3D, wave_amp: Vector2.new(0.06_f32, 0.06_f32), wave_freq: Vector2.new(2.5_f32, 2.5_f32), wave_speed: 2.0)
  end

  # Preset factory: 90s comic book halftone print with dithered lighting and hatched drop shadow.
  def self.comic_halftone : UniversalMaterial
    new
      .set_pattern("polka_dots")
      .set_theme(Palette::Theme::VaporwaveSunset, use_tritone: true)
      .set_outline(enabled: true, width: 3.5, mode: OutlineMode::Center, boil_amp: 0.08, boil_freq: 10.0)
      .set_cel_shading(enabled: true, strength: 0.4, bands: 2, dither_light: true)
      .set_drop_shadow(enabled: true, offset: Vector2.new(5.0_f32, -5.0_f32), color: "deep_indigo", dither: true, use_pattern: true)
      .set_dither(enabled: true, strength: 0.6, pixel_size: 2.0)
      .set_transform(scale: 2.2)
  end

  # Preset factory: glossy enamel pin badge with metallic bevel and inner/outer rim.
  def self.enamel_pin_badge : UniversalMaterial
    new
      .set_pattern("glamorous")
      .set_theme(Palette::Theme::PeachCream, use_tritone: true)
      .set_outline(enabled: true, width: 3.0, mode: OutlineMode::Center)
      .set_bevel(enabled: true, strength: 0.85, angle: 2.1)
      .set_fresnel(enabled: true, power: 3.0, color: "warm_cream")
      .set_drop_shadow(enabled: true, offset: Vector2.new(3.0_f32, -3.0_f32), color: "deep_indigo")
      .set_transform(scale: 1.75)
  end

  # Preset factory: kaleidoscopic VHS glitch portal with chromatic RGB split and spherical/radial symmetry.
  def self.vhs_glitch_portal : UniversalMaterial
    new
      .set_pattern("wiggle")
      .set_theme(Palette::Theme::NeonPlum, use_tritone: true)
      .set_3d_surface(ProjectionMode::Camera, use_base_texture: false, tile_base_texture: true)
      .set_outline(enabled: false)
      .set_transform(scale: 2.0, mirror_tiles: true, kaleidoscope_segments: 8)
      .set_rotation_motion(linear_speed: 0.45, wave_mode: RotationWaveMode::Sin, wave_amp: 0.35, wave_freq: 1.2)
      .set_ripple(enabled: true, mode: RippleMode::RadialRipple, amp: Vector2.new(0.08_f32, 0.08_f32), freq: Vector2.new(8.0_f32, 8.0_f32), speed: Vector2.new(3.5_f32, 3.5_f32))
      .set_retro_crt(glitch_intensity: 0.35, scanline_strength: 0.4, scanline_density: 160.0, emission_strength: 0.9)
      .set_surface_fx(pixel_size: 2.0, chromatic_split: 0.015)
  end

  private def format_tres_value(v : ParamValue) : String
    case v
    when Bool
      v ? "true" : "false"
    when Int64
      v.to_s
    when Float64
      v.round(5).to_s
    when String
      v.inspect
    when Color
      "Color(#{v.r.round(6)}, #{v.g.round(6)}, #{v.b.round(6)}, #{v.a.round(6)})"
    when Vector2
      "Vector2(#{v.x.round(5)}, #{v.y.round(5)})"
    when Vector3
      "Vector3(#{v.x.round(5)}, #{v.y.round(5)}, #{v.z.round(5)})"
    else
      "0"
    end
  end
end

alias PatternMaterial = UniversalMaterial

# Custom Godot `ShaderMaterial` resource pre-configured with `pattern_replace.gdshader`,
# `Palette` color/theme selectors, and `Patterns` / `PatternGenerator` Inspector controls.
@[Tool]
resource PatternShaderMaterial < ShaderMaterial do
  @[Export]
  property preset_pattern : String = "default_pattern"

  @[ExportEnum(Palette::Theme)]
  property theme_preset : Palette::Theme = Palette::Theme::WatermelonPunch

  @[ExportEnum(Palette::ColorId)]
  property fg_palette : Palette::ColorId = Palette::ColorId::HotWatermelon

  @[ExportEnum(Palette::ColorId)]
  property bg_palette : Palette::ColorId = Palette::ColorId::DeepIndigo

  @[ExportEnum(Palette::ColorId)]
  property outline_palette : Palette::ColorId = Palette::ColorId::White

  @[Export]
  property generator : PatternGenerator? = nil

  def pointer=(val : Void*)
    super(val)
    ensure_shader! if !val.null?
  end

  def preset_pattern=(val : String)
    @preset_pattern = val
    if !@pointer.null? && Patterns.has?(val)
      Patterns.apply_to(self, val)
    end
  end

  def theme_preset=(val : Palette::Theme)
    @theme_preset = val
    tc = Palette.theme(val)
    @fg_palette = tc.fg
    @bg_palette = tc.bg
    @outline_palette = tc.outline
    if !@pointer.null?
      Palette.apply_theme(self, val)
    end
  end

  def fg_palette=(val : Palette::ColorId)
    @fg_palette = val
    if !@pointer.null?
      call("set_shader_parameter", "fg_color", Palette[val.value])
    end
  end

  def bg_palette=(val : Palette::ColorId)
    @bg_palette = val
    if !@pointer.null?
      call("set_shader_parameter", "bg_color", Palette[val.value])
    end
  end

  def outline_palette=(val : Palette::ColorId)
    @outline_palette = val
    if !@pointer.null?
      call("set_shader_parameter", "outline_color", Palette[val.value])
    end
  end

  def generator=(val : PatternGenerator?)
    @generator = val
    if gen = val
      gen.apply_to(self) if !@pointer.null?
    end
  end

  @[ExportToolButton("Apply Theme Preset", icon: "ColorPicker")]
  def apply_theme_button : Void
    self.theme_preset = @theme_preset
  end

  @[ExportToolButton("Randomize Pattern & Colors", icon: "RandomNumberGenerator")]
  def randomize_button : Void
    random_pat = Patterns.ids.sample
    random_theme = Palette::Theme.values.sample
    self.preset_pattern = random_pat
    self.theme_preset = random_theme
  end

  # Ensures `pattern_replace.gdshader` is assigned to this `ShaderMaterial`.
  def ensure_shader! : Void
    return if @pointer.null?
    current = get_shader
    if current.pointer.null?
      if sh = Godot.preload?(UniversalMaterial::SHADER_PATH, Shader)
        set_shader(sh) if !sh.pointer.null?
      end
    end
  rescue
  end

  # Returns a fluent `UniversalMaterial` builder wrapping `self`.
  def builder : UniversalMaterial
    UniversalMaterial.new(self)
  end
end
