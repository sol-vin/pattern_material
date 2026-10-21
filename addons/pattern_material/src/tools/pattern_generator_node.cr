require "lapis"
require "../generators/generators"
require "../resources/universal_material"

include Godot

# In-editor `@[Tool]` helper node for visually designing procedural patterns,
# previewing them live on a target 2D/3D node's `ShaderMaterial`, and exporting
# custom `.svg` textures directly to `res://addons/pattern_material/textures/patterns/`.
@[Tool]
node PatternGeneratorTool < Node do
  @[ExportEnum(CustomPatternGenerator::PatternKind)]
  property kind : CustomPatternGenerator::PatternKind = CustomPatternGenerator::PatternKind::PolkaDots

  @[Export(range: 16..1024, step: 1)]
  property tile_size : Int64 = 128_i64

  @[Export(range: 1..32, step: 1)]
  property columns : Int64 = 2_i64

  @[Export(range: 1..32, step: 1)]
  property rows : Int64 = 2_i64

  @[Export(range: 1.0..100.0, step: 0.5)]
  property primary_size : Float64 = 18.0

  @[Export(range: 0.0..50.0, step: 0.5)]
  property secondary_size : Float64 = 6.0

  @[Export]
  property stagger : Bool = true

  @[Export]
  property invert : Bool = false

  @[Export(range: -180.0..180.0, step: 1.0)]
  property pattern_rotation : Float64 = 0.0

  @[ExportEnum(Palette::ColorId)]
  property fg_palette : Palette::ColorId = Palette::ColorId::HotWatermelon

  @[ExportEnum(Palette::ColorId)]
  property bg_palette : Palette::ColorId = Palette::ColorId::DeepIndigo

  @[Export]
  property target_node_path : String = ""

  @[Export]
  property output_svg_path : String = "res://addons/pattern_material/textures/patterns/custom_generated.svg"

  def kind=(val : CustomPatternGenerator::PatternKind)
    @kind = val
    apply_live_preview
  end

  def tile_size=(val : Int64)
    @tile_size = val
    apply_live_preview
  end

  def columns=(val : Int64)
    @columns = val
    apply_live_preview
  end

  def rows=(val : Int64)
    @rows = val
    apply_live_preview
  end

  def primary_size=(val : Float64)
    @primary_size = val
    apply_live_preview
  end

  def secondary_size=(val : Float64)
    @secondary_size = val
    apply_live_preview
  end

  def stagger=(val : Bool)
    @stagger = val
    apply_live_preview
  end

  def invert=(val : Bool)
    @invert = val
    apply_live_preview
  end

  def pattern_rotation=(val : Float64)
    @pattern_rotation = val
    apply_live_preview
  end

  def fg_palette=(val : Palette::ColorId)
    @fg_palette = val
    apply_live_preview
  end

  def bg_palette=(val : Palette::ColorId)
    @bg_palette = val
    apply_live_preview
  end

  # Builds a `CustomPatternGenerator` matching the current Inspector settings.
  def build_generator : CustomPatternGenerator
    gen = Patterns.custom(
      kind: @kind,
      columns: @columns.to_i32,
      rows: @rows.to_i32,
      primary_size: @primary_size,
      secondary_size: @secondary_size,
      stagger: @stagger,
      tile_size: @tile_size.to_i32,
      invert: @invert
    )
    gen.pattern_rotation = @pattern_rotation
    gen.export_svg_path = @output_svg_path
    gen
  end

  @[ExportToolButton("Preview Pattern on Target", icon: "Play")]
  def apply_live_preview : Void
    return if @pointer.null?
    target = resolve_target_node
    return unless target && !target.pointer.null?

    mat = extract_shader_material(target)
    return unless mat && !mat.pointer.null?

    gen = build_generator
    gen.apply_to(mat)
    mat.call("set_shader_parameter", "fg_color", Palette[@fg_palette.value])
    mat.call("set_shader_parameter", "bg_color", Palette[@bg_palette.value])
  rescue
  end

  @[ExportToolButton("Export Pattern to SVG", icon: "Save")]
  def export_pattern_svg : Void
    gen = build_generator
    saved = gen.save_svg(@output_svg_path)
    SvgSpritesheetBuilder.ensure_lossless_svg_import(saved, SvgSpritesheetBuilder.to_res_path(@output_svg_path))
    Godot.print("[PatternGeneratorTool] Exported procedural pattern SVG to #{saved}")
  rescue ex
    Godot.printerr("[PatternGeneratorTool] Failed to export SVG: #{ex.message}")
  end

  private def resolve_target_node : Node?
    path = @target_node_path.strip
    if !path.empty?
      return get_node_or_null(path)
    end
    get_parent
  end

  private def extract_shader_material(target : Node) : ShaderMaterial?
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
  end
end
