require "lapis"
require "./svg_spritesheet_builder"

include Godot

# In-editor tool node for packing all face SVGs in `textures/fontawesome/faces`
# into the padded `textures/fontawesome/faces.svg` texture atlas spritesheet.
# Delegates core normalization and atlas building to `SvgSpritesheetBuilder`.
@[Tool]
node FacesSpritesheetBuilder < Node do
  DEFAULT_FACES_DIR   = Faces::SOURCE_DIR
  DEFAULT_OUTPUT_PATH = Faces::TEXTURE_PATH
  DEFAULT_COLUMNS     = Faces::DEFAULT_COLS
  DEFAULT_ICON_SIZE   = Faces::ICON_SIZE
  DEFAULT_PADDING     = Faces::PADDING

  alias Result = SvgSpritesheetBuilder::Result

  @[Export]
  property faces_dir : String = DEFAULT_FACES_DIR

  @[Export]
  property output_path : String = DEFAULT_OUTPUT_PATH

  @[Export(range: 1..64, step: 1)]
  property columns : Int64 = DEFAULT_COLUMNS.to_i64

  @[Export(range: 64..2048, step: 1)]
  property icon_size : Int64 = DEFAULT_ICON_SIZE.to_i64

  @[Export(range: 0..512, step: 1)]
  property padding : Int64 = DEFAULT_PADDING.to_i64

  @[ExportToolButton("Rebuild faces.svg", icon: "Reload")]
  def rebuild_faces_svg : Void
    res = FacesSpritesheetBuilder.generate(
      faces_dir: faces_dir,
      output_path: output_path,
      columns: columns.to_i32,
      icon_size: icon_size.to_i32,
      padding: padding.to_i32
    )
    sync_head_atlas_grid(res.columns, res.rows)
    Godot.print("[FacesSpritesheetBuilder] Built #{res.output_path} (#{res.count} faces, #{res.columns}x#{res.rows} grid)")
  rescue ex
    Godot.printerr("[FacesSpritesheetBuilder] Failed to build spritesheet: #{ex.message}")
  end

  @[ExportToolButton("Rebuild letter_glyphs.svg", icon: "Reload")]
  def rebuild_letter_glyphs_svg : Void
    res = SvgSpritesheetBuilder.generate(SvgSpritesheetBuilder::LETTER_GLYPHS_CONFIG)
    Godot.print("[FacesSpritesheetBuilder] Built #{res.output_path} (#{res.count} glyphs, #{res.columns}x#{res.rows} grid)")
  rescue ex
    Godot.printerr("[FacesSpritesheetBuilder] Failed to build letter_glyphs spritesheet: #{ex.message}")
  end

  @[ExportToolButton("Rebuild All Spritesheets", icon: "Reload")]
  def rebuild_all_spritesheets : Void
    results = SvgSpritesheetBuilder.generate_all
    results.each do |res|
      if res.atlas.atlas_name == Faces::ATLAS_NAME
        sync_head_atlas_grid(res.columns, res.rows)
      end
      Godot.print("[FacesSpritesheetBuilder] Built #{res.output_path} (#{res.count} icons, #{res.columns}x#{res.rows} grid)")
    end
  rescue ex
    Godot.printerr("[FacesSpritesheetBuilder] Failed to build all spritesheets: #{ex.message}")
  end

  # Updates `%Head`'s ShaderMaterial `hframes` and `vframes` parameters in the active scene.
  def sync_head_atlas_grid(cols : Int32, rows : Int32) : Void
    head_node = get_node_or_null("%Head") ||
                get_node_or_null("../%Head") ||
                get_node_or_null("../Head")
    if head_node.nil? && Godot.editor_hint? && !Godot::EditorInterface.singleton_ptr.null?
      ei = Godot::EditorInterface.new(Godot::EditorInterface.singleton_ptr)
      if root = ei.get_edited_scene_root
        if !root.pointer.null?
          head_node = root.get_node_or_null("%Head") || root.get_node_or_null("Head")
        end
      end
    end

    if h = head_node
      if !h.pointer.null?
        if mesh = h.call_obj("get_mesh")
          mat = mesh.call_obj("surface_get_material", 0_i64) || mesh.call_obj("get_material")
          if mat && !mat.pointer.null?
            mat.call("set_shader_parameter", "hframes", cols.to_i64)
            mat.call("set_shader_parameter", "vframes", rows.to_i64)
          end
        end
      end
    end
  rescue
  end

  # Normalizes a single face SVG string so that any shape with `opacity` has its
  # opacity removed and its fill changed to solid white (`#ffffff`).
  def self.normalize_face_svg(svg_content : String) : String
    SvgSpritesheetBuilder.normalize_svg(svg_content)
  end

  # Extracts all `<path .../>` elements from a normalized SVG string.
  def self.extract_paths(svg_content : String) : Array(String)
    SvgSpritesheetBuilder.extract_paths(svg_content)
  end

  # Scans `faces_dir` for all `.svg` files, normalizes each file in-place if needed,
  # and writes the combined padded spritesheet to `output_path`.
  def self.generate(
    faces_dir : String = DEFAULT_FACES_DIR,
    output_path : String = DEFAULT_OUTPUT_PATH,
    columns : Int32 = DEFAULT_COLUMNS,
    icon_size : Int32 = DEFAULT_ICON_SIZE,
    padding : Int32 = DEFAULT_PADDING
  ) : Result
    res_path = (output_path == DEFAULT_OUTPUT_PATH) ? Faces::RESOURCE_PATH : ""
    SvgSpritesheetBuilder.generate(
      source_dir: faces_dir,
      output_path: output_path,
      resource_path: res_path,
      strip_prefix: Faces::STRIP_PREFIX,
      atlas_name: Faces::ATLAS_NAME,
      title: "Faces",
      columns: columns,
      icon_size: icon_size,
      padding: padding,
      aliases: Faces::ALIASES
    )
  end

  def self.resolve_filesystem_path(path : String) : String
    SvgSpritesheetBuilder.resolve_filesystem_path(path)
  end
end
