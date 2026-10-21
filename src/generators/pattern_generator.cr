require "lapis"

include Godot

# Base procedural SVG and `ImageTexture` pattern generator for `PatternMaterial` / `pattern_replace.gdshader`.
#
# Because `PatternGenerator` inherits from `Godot::ImageTexture` (`< Texture2D`), any generator subclass
# can be assigned directly into the `custom_pattern` texture slot in the Godot Inspector or via code,
# and automatically re-rasterizes its SVG whenever any `@[Export]` parameter is adjusted.
@[Tool]
resource PatternGenerator < ImageTexture do
  @[Export(range: 16..1024, step: 1)]
  property tile_size : Int64 = 128_i64

  @[Export(range: 16.0..512.0, step: 1.0)]
  property view_size : Float64 = 100.0

  @[Export]
  property invert : Bool = false

  @[Export(range: -180.0..180.0, step: 1.0)]
  property pattern_rotation : Float64 = 0.0

  @[Export]
  property pattern_offset : Vector2 = Vector2.new(0.0_f32, 0.0_f32)

  @[Export]
  property export_svg_path : String = ""

  def tile_size=(val : Int64)
    return if @tile_size == val
    @tile_size = val
    refresh_texture!
  end

  def view_size=(val : Float64)
    return if @view_size == val
    @view_size = val
    refresh_texture!
  end

  def invert=(val : Bool)
    return if @invert == val
    @invert = val
    refresh_texture!
  end

  def pattern_rotation=(val : Float64)
    return if @pattern_rotation == val
    @pattern_rotation = val
    refresh_texture!
  end

  def pattern_offset=(val : Vector2)
    return if @pattern_offset == val
    @pattern_offset = val
    refresh_texture!
  end

  def pointer=(val : Void*)
    super(val)
    refresh_texture! if !val.null?
  end

  @[ExportToolButton("Refresh Pattern Preview", icon: "Reload")]
  def refresh_pattern_button : Void
    refresh_texture!
  end

  @[ExportToolButton("Export SVG File", icon: "Save")]
  def save_svg_button : Void
    target = @export_svg_path.strip
    if target.empty?
      Godot.printerr("[PatternGenerator] Set export_svg_path before exporting SVG.")
      return
    end
    saved = save_svg(target)
    Godot.print("[PatternGenerator] Saved procedural pattern SVG to #{saved}")
  rescue ex
    Godot.printerr("[PatternGenerator] Failed to save SVG: #{ex.message}")
  end

  # Returns the foreground hex color (`#ffffff` by default, or `#000000` when `invert` is true).
  def fg_hex : String
    @invert ? "#000000" : "#ffffff"
  end

  # Returns the background hex color (`#000000` by default, or `#ffffff` when `invert` is true).
  def bg_hex : String
    @invert ? "#ffffff" : "#000000"
  end

  # Overridden by subclasses to emit SVG pattern elements into `io` within `0..size` coordinate space.
  def build_svg_body(io : IO, size : Float64, fg : String, bg : String) : Void
    half = size * 0.5
    r = size * 0.25
    io << %(  <circle cx="#{fmt(half)}" cy="#{fmt(half)}" r="#{fmt(r)}" fill="#{fg}"/>\n)
  end

  # Generates the complete black-and-white repeating SVG document string for this pattern.
  def to_svg : String
    px = Math.max(@tile_size.to_i32, 16)
    vs = Math.max(@view_size, 16.0)
    fg = fg_hex
    bg = bg_hex

    has_transform = (@pattern_rotation.abs > 1e-4) || (@pattern_offset.x.abs > 1e-4) || (@pattern_offset.y.abs > 1e-4)

    String.build do |io|
      io << %(<svg xmlns="http://www.w3.org/2000/svg" width="#{px}" height="#{px}" viewBox="0 0 #{fmt(vs)} #{fmt(vs)}">\n)
      io << %(  <rect width="#{fmt(vs)}" height="#{fmt(vs)}" fill="#{bg}"/>\n)
      if has_transform
        cx = vs * 0.5
        cy = vs * 0.5
        transforms = [] of String
        if @pattern_offset.x.abs > 1e-4 || @pattern_offset.y.abs > 1e-4
          transforms << "translate(#{fmt(@pattern_offset.x.to_f64)},#{fmt(@pattern_offset.y.to_f64)})"
        end
        if @pattern_rotation.abs > 1e-4
          transforms << "rotate(#{fmt(@pattern_rotation)},#{fmt(cx)},#{fmt(cy)})"
        end
        io << %(  <g transform="#{transforms.join(" ")}">\n)
        build_svg_body(io, vs, fg, bg)
        io << %(  </g>\n)
      else
        build_svg_body(io, vs, fg, bg)
      end
      io << %(</svg>\n)
    end
  end

  # Rasterizes `to_svg` into a `Godot::Image` when running inside Godot.
  def to_image : Image
    img = Godot.create(Image)
    if !img.pointer.null?
      img.load_svg_from_string(to_svg, 1.0_f64)
    end
    img
  rescue
    Image.new
  end

  # Rebuilds the in-memory `ImageTexture` from `to_svg` when backed by a live Godot instance.
  def refresh_texture! : Void
    return if @pointer.null?
    img = to_image
    if !img.pointer.null?
      set_image(img)
      emit_changed
    end
  rescue
  end

  # Writes the generated SVG string to `path` (supports `res://` or filesystem paths) and returns the resolved path.
  def save_svg(path : String = @export_svg_path) : String
    target = path.strip
    raise ArgumentError.new("SVG export path cannot be empty") if target.empty?

    resolved = resolve_filesystem_path(target)
    dir = File.dirname(resolved)
    Dir.mkdir_p(dir) unless Dir.exists?(dir)
    File.write(resolved, to_svg)
    resolved
  end

  # Assigns this procedural pattern generator to a `ShaderMaterial`'s `custom_pattern` parameter.
  def apply_to(material : ShaderMaterial) : self
    refresh_texture!
    if !material.pointer.null? && !@pointer.null?
      material.call("set_shader_parameter", "custom_pattern", self)
    end
    self
  end

  protected def fmt(val : Float64) : String
    rounded = val.round(3)
    if (rounded - rounded.round).abs < 1e-5
      rounded.to_i64.to_s
    else
      rounded.to_s
    end
  end

  protected def resolve_filesystem_path(path : String) : String
    if path.starts_with?("res://")
      if Godot.editor_hint?
        ps = Godot::ProjectSettings.instance rescue nil
        if ps && !ps.pointer.null?
          globalized = ps.globalize_path(path) rescue ""
          return globalized unless globalized.empty?
        end
      end
      return path.sub(/^res:\/\//, "")
    end
    path
  end
end
