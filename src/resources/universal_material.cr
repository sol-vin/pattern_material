require "lapis"
require "./spritesheets"
require "./patterns"
require "./palette"

include Godot

# Ergonomic wrapper and fluent builder around a `ShaderMaterial` backed by
# `res://addons/pattern_material/shaders/pattern_replace.gdshader`.
#
# Combines `Faces`, `Glyphs`, `Patterns`, `PatternGenerator`, and `Palette` with typed
# helper methods for configuring projection modes, outlines, bevels, drop shadows,
# retro dithering, dissolve wipes, and vertex effects.
class UniversalMaterial
  SHADER_PATH        = "res://addons/pattern_material/shaders/pattern_replace.gdshader"
  LEGACY_SHADER_PATH = "res://shaders/pattern_replace.gdshader"

  enum ProjectionMode
    Camera         = 0
    ModelNormals   = 1
    WorldTriplanar = 2
    MeshUV         = 3
    Cylindrical    = 4
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
  getter parameters : Hash(String, Bool | Int64 | Float64 | String | Color | Vector2)
  getter generator : PatternGenerator? = nil

  def initialize(@material : ShaderMaterial = ShaderMaterial.new)
    @parameters = Hash(String, Bool | Int64 | Float64 | String | Color | Vector2).new
  end

  # Sets a shader parameter on both the underlying Godot `ShaderMaterial` (when active)
  # and the local parameter mirror for inspection/testing.
  def set_param(name : String, value : Bool | Int64 | Float64 | String | Color | Vector2) : self
    @parameters[name] = value
    if !@material.pointer.null?
      @material.call("set_shader_parameter", name, value)
    end
    self
  end

  def get_param?(name : String)
    @parameters[name]?
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
    fg : Int | String | Symbol | Color,
    bg : Int | String | Symbol | Color,
    outline : (Int | String | Symbol | Color)? = nil,
    unreplaced : (Int | String | Symbol | Color)? = nil
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
    color : (Int | String | Symbol | Color)? = nil
  ) : self
    set_param("fresnel_enabled", enabled)
    set_param("fresnel_power", power)
    set_param("fresnel_invert_pattern", invert_pattern)
    if c = color
      set_param("fresnel_color", Palette.resolve(c))
    end
    self
  end

  # Configures the 2.5D offset paper-cutout drop shadow.
  def set_drop_shadow(
    enabled : Bool = true,
    offset : Vector2 = Vector2.new(4.0_f32, -4.0_f32),
    color : Int | String | Symbol | Color = "deep_indigo"
  ) : self
    set_param("shadow_enabled", enabled)
    set_param("shadow_offset", offset)
    set_param("shadow_color", Palette.resolve(color))
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
    edge_color : Int | String | Symbol | Color = "white"
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
end

alias PatternMaterial = UniversalMaterial

# Custom Godot `ShaderMaterial` resource pre-configured with `pattern_replace.gdshader`,
# `Palette` color selectors, and `Patterns` / `PatternGenerator` Inspector controls.
@[Tool]
resource PatternShaderMaterial < ShaderMaterial do
  @[Export]
  property preset_pattern : String = "default_pattern"

  @[ExportEnum(Palette::ColorId)]
  property fg_palette : Palette::ColorId = Palette::ColorId::HotWatermelon

  @[ExportEnum(Palette::ColorId)]
  property bg_palette : Palette::ColorId = Palette::ColorId::DeepIndigo

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

  def generator=(val : PatternGenerator?)
    @generator = val
    if gen = val
      gen.apply_to(self) if !@pointer.null?
    end
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
