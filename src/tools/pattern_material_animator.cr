require "lapis"
require "../resources/universal_material"

include Godot

# Attachable `@[Tool]` node for animating a target node's `PatternMaterial` (`pattern_replace.gdshader`)
# in both the Godot Editor and at runtime.
#
# Supports:
# - **Spritesheet Flipbook Sequences**: Cycles through a comma-separated list of `Faces`, `Glyphs`,
#   or custom frame indices at `flipbook_fps` (forward loop or ping-pong).
# - **Palette Theme Cycling**: Smoothly cross-fades or step-cycles through `Palette::Theme` harmonies.
# - **Dissolve & Glitch Triggers**: One-call methods and Inspector buttons for dissolve-in,
#   dissolve-out, and VHS glitch bursts.
@[Tool]
node PatternMaterialAnimator < Node do
  enum AtlasSource
    Faces  = 0
    Glyphs = 1
    Frames = 2
  end

  @[Export]
  property target_node_path : String = ""

  @[Export]
  property flipbook_enabled : Bool = false

  @[ExportEnum(PatternMaterialAnimator::AtlasSource)]
  property atlas_source : AtlasSource = AtlasSource::Faces

  @[Export]
  property frame_keys_csv : String = "smile,smile-wink,laugh"

  @[Export(range: 0.5..60.0, step: 0.5)]
  property flipbook_fps : Float64 = 6.0

  @[Export]
  property ping_pong : Bool = false

  @[Export]
  property palette_cycle_enabled : Bool = false

  @[Export]
  property cycle_themes_csv : String = "watermelon_punch,cyber_mint,vaporwave_sunset"

  @[Export(range: 0.1..20.0, step: 0.1)]
  property cycle_speed : Float64 = 1.5

  @[Export]
  property smooth_palette_lerp : Bool = true

  @[Export(range: 0.1..10.0, step: 0.05)]
  property dissolve_duration : Float64 = 0.8

  @elapsed : Float64 = 0.0
  @dissolve_active : Bool = false
  @dissolve_target : Float64 = 0.0
  @dissolve_current : Float64 = 0.0
  @glitch_timer : Float64 = 0.0
  @glitch_burst_amp : Float64 = 0.0

  getter elapsed : Float64
  getter dissolve_current : Float64

  def _process(delta : Float64) : Void
    step_animation(delta)
  end

  # Advances all active flipbook, palette cycle, dissolve, and glitch animations by `delta` seconds.
  def step_animation(delta : Float64) : Void
    return if delta <= 0.0
    @elapsed += delta

    mat = resolve_target_material

    if @flipbook_enabled
      idx = current_flipbook_frame_index
      if idx >= 0 && mat && !mat.pointer.null?
        mat.call("set_shader_parameter", "frame", idx.to_i64)
      end
    end

    if @palette_cycle_enabled
      fg_col, bg_col = current_cycled_colors
      if mat && !mat.pointer.null?
        mat.call("set_shader_parameter", "fg_color", fg_col)
        mat.call("set_shader_parameter", "bg_color", bg_col)
      end
    end

    if @dissolve_active
      dur = Math.max(@dissolve_duration, 0.05)
      step = delta / dur
      if (@dissolve_target - @dissolve_current).abs <= step
        @dissolve_current = @dissolve_target
        @dissolve_active = false
      elsif @dissolve_target > @dissolve_current
        @dissolve_current += step
      else
        @dissolve_current -= step
      end
      if mat && !mat.pointer.null?
        mat.call("set_shader_parameter", "dissolve_amount", @dissolve_current.clamp(0.0, 1.0))
      end
    end

    if @glitch_timer > 0.0
      @glitch_timer = Math.max(@glitch_timer - delta, 0.0)
      amp = @glitch_timer > 0.0 ? @glitch_burst_amp : 0.0
      if mat && !mat.pointer.null?
        mat.call("set_shader_parameter", "glitch_intensity", amp)
      end
    end
  end

  # Resolves the list of 0-based atlas frame indices from `frame_keys_csv` and `atlas_source`.
  def resolved_frame_indices : Array(Int32)
    tokens = @frame_keys_csv.split(',', remove_empty: true).map(&.strip).reject(&.empty?)
    indices = [] of Int32
    tokens.each do |tok|
      case @atlas_source
      when AtlasSource::Faces
        if idx = Faces[tok]?
          indices << idx
        elsif n = tok.to_i32?
          indices << n
        end
      when AtlasSource::Glyphs
        if idx = Glyphs[tok]?
          indices << idx
        elsif n = tok.to_i32?
          indices << n
        end
      when AtlasSource::Frames
        if n = tok.to_i32?
          indices << n
        end
      end
    end
    indices
  end

  # Computes the active 0-based sprite frame index at the current `@elapsed` time.
  def current_flipbook_frame_index : Int32
    frames = resolved_frame_indices
    return -1 if frames.empty?
    return frames[0] if frames.size == 1

    total_steps = (@elapsed * Math.max(@flipbook_fps, 0.1)).to_i64
    n = frames.size
    slot = if @ping_pong && n > 2
             period = (n - 1) * 2
             pos = (total_steps % period).to_i32
             pos < n ? pos : (period - pos)
           else
             (total_steps % n).to_i32
           end
    frames[slot]
  end

  # Resolves the list of `Palette::ThemeColors` from `cycle_themes_csv`.
  def resolved_cycle_themes : Array(Palette::ThemeColors)
    tokens = @cycle_themes_csv.split(',', remove_empty: true).map(&.strip).reject(&.empty?)
    themes = [] of Palette::ThemeColors
    tokens.each do |tok|
      if tc = Palette.theme?(tok)
        themes << tc
      end
    end
    themes << Palette.theme(Palette::Theme::WatermelonPunch) if themes.empty?
    themes
  end

  # Computes the active `(fg_color, bg_color)` pair at the current `@elapsed` time.
  def current_cycled_colors : {Color, Color}
    themes = resolved_cycle_themes
    return {themes[0].fg_color, themes[0].bg_color} if themes.size == 1

    phase = @elapsed * Math.max(@cycle_speed, 0.05)
    idx_a = phase.floor.to_i64 % themes.size
    idx_b = (idx_a + 1) % themes.size
    t = (phase - phase.floor).to_f32

    ta = themes[idx_a]
    tb = themes[idx_b]

    if @smooth_palette_lerp
      fg = lerp_color(ta.fg_color, tb.fg_color, t)
      bg = lerp_color(ta.bg_color, tb.bg_color, t)
      {fg, bg}
    else
      {ta.fg_color, ta.bg_color}
    end
  end

  # Starts a smooth dissolve-out transition (`dissolve_amount` -> `1.0`).
  @[ExportToolButton("Trigger Dissolve Out", icon: "GuiVisibilityHidden")]
  def dissolve_out! : Void
    @dissolve_target = 1.0
    @dissolve_active = true
  end

  # Starts a smooth dissolve-in transition (`dissolve_amount` -> `0.0`).
  @[ExportToolButton("Trigger Dissolve In", icon: "GuiVisibilityVisible")]
  def dissolve_in! : Void
    @dissolve_current = 1.0 if @dissolve_current <= 0.0
    @dissolve_target = 0.0
    @dissolve_active = true
  end

  # Triggers a timed VHS glitch tear burst from the Godot Inspector.
  @[ExportToolButton("Trigger Glitch Burst", icon: "Sparkles")]
  def trigger_glitch_button : Void
    glitch_burst!(0.35, 0.65)
  end

  # Triggers a timed VHS glitch tear burst.
  def glitch_burst!(duration : Float64 = 0.35, intensity : Float64 = 0.65) : Void
    @glitch_timer = Math.max(duration, 0.05)
    @glitch_burst_amp = intensity.clamp(0.0, 1.0)
    if mat = resolve_target_material
      mat.call("set_shader_parameter", "glitch_intensity", @glitch_burst_amp) if !mat.pointer.null?
    end
  end

  private def lerp_color(a : Color, b : Color, t : Float32) : Color
    Color.new(
      a.r + (b.r - a.r) * t,
      a.g + (b.g - a.g) * t,
      a.b + (b.b - a.b) * t,
      a.a + (b.a - a.a) * t
    )
  end

  private def resolve_target_node : Node?
    return nil if @pointer.null?
    path = @target_node_path.strip
    if !path.empty?
      return get_node_or_null(path)
    end
    get_parent
  rescue
    nil
  end

  private def resolve_target_material : ShaderMaterial?
    target = resolve_target_node
    return nil unless target && !target.pointer.null?
    if m = target.call_obj("get_material_override")
      return ShaderMaterial.new(m.pointer) if !m.pointer.null?
    end
    if m = target.call_obj("get_material")
      return ShaderMaterial.new(m.pointer) if !m.pointer.null?
    end
    if mesh = target.call_obj("get_mesh")
      if !mesh.pointer.null?
        if m = mesh.call_obj("surface_get_material", 0_i64) || mesh.call_obj("get_material")
          return ShaderMaterial.new(m.pointer) if !m.pointer.null?
        end
      end
    end
    nil
  rescue
    nil
  end
end
