require "lapis"
require "../resources/spritesheet_atlas"
require "../resources/spritesheets"

include Godot

# Standardized in-editor tool node and builder for packing a directory of FontAwesome
# duotone SVGs into a padded grid `.svg` texture atlas and generating its
# corresponding `.tres` `SpritesheetAtlas` resource.
@[Tool]
node SvgSpritesheetBuilder < Node do
  DEFAULT_COLUMNS      =  12
  DEFAULT_ICON_SIZE    = 640
  DEFAULT_PADDING      =  64
  DEFAULT_CELL_PX_SIZE =   0

  # Configuration for a single spritesheet build target.
  struct Config
    getter name : String
    getter title : String
    getter source_dir : String
    getter output_path : String
    getter resource_path : String
    getter strip_prefix : String
    getter columns : Int32
    getter icon_size : Int32
    getter padding : Int32
    getter cell_px_size : Int32
    getter aliases : Hash(String, String)

    def initialize(
      @name : String,
      @title : String,
      @source_dir : String,
      @output_path : String,
      @resource_path : String = "",
      @strip_prefix : String = "",
      @columns : Int32 = DEFAULT_COLUMNS,
      @icon_size : Int32 = DEFAULT_ICON_SIZE,
      @padding : Int32 = DEFAULT_PADDING,
      @cell_px_size : Int32 = DEFAULT_CELL_PX_SIZE,
      @aliases : Hash(String, String) = Hash(String, String).new
    )
    end
  end

  # Summary of a completed spritesheet generation run.
  struct Result
    getter count : Int32
    getter columns : Int32
    getter rows : Int32
    getter cell_px_size : Int32
    getter output_path : String
    getter resource_path : String
    getter item_ids : Array(String)
    getter item_keys : Array(String)
    getter atlas : SpritesheetAtlas

    def initialize(
      @count : Int32,
      @columns : Int32,
      @rows : Int32,
      @output_path : String,
      @resource_path : String = "",
      @item_ids : Array(String) = [] of String,
      @item_keys : Array(String) = [] of String,
      @atlas : SpritesheetAtlas = SpritesheetAtlas.new,
      @cell_px_size : Int32 = 384
    )
    end
  end

  FACES_CONFIG = Config.new(
    name: Faces::ATLAS_NAME,
    title: "Faces",
    source_dir: Faces::SOURCE_DIR,
    output_path: Faces::TEXTURE_PATH,
    resource_path: Faces::RESOURCE_PATH,
    strip_prefix: Faces::STRIP_PREFIX,
    columns: Faces::DEFAULT_COLS,
    icon_size: Faces::ICON_SIZE,
    padding: Faces::PADDING,
    cell_px_size: Faces::CELL_PX_SIZE,
    aliases: Faces::ALIASES
  )

  LETTER_GLYPHS_CONFIG = Config.new(
    name: Glyphs::ATLAS_NAME,
    title: "Letter Glyphs",
    source_dir: Glyphs::SOURCE_DIR,
    output_path: Glyphs::TEXTURE_PATH,
    resource_path: Glyphs::RESOURCE_PATH,
    strip_prefix: Glyphs::STRIP_PREFIX,
    columns: Glyphs::DEFAULT_COLS,
    icon_size: Glyphs::ICON_SIZE,
    padding: Glyphs::PADDING,
    cell_px_size: Glyphs::CELL_PX_SIZE
  )

  PRESETS = [FACES_CONFIG, LETTER_GLYPHS_CONFIG]

  @[Export]
  property atlas_name : String = LETTER_GLYPHS_CONFIG.name

  @[Export]
  property source_dir : String = LETTER_GLYPHS_CONFIG.source_dir

  @[Export]
  property output_path : String = LETTER_GLYPHS_CONFIG.output_path

  @[Export]
  property resource_path : String = LETTER_GLYPHS_CONFIG.resource_path

  @[Export]
  property strip_prefix : String = LETTER_GLYPHS_CONFIG.strip_prefix

  @[Export(range: 1..64, step: 1)]
  property columns : Int64 = DEFAULT_COLUMNS.to_i64

  @[Export(range: 64..2048, step: 1)]
  property icon_size : Int64 = DEFAULT_ICON_SIZE.to_i64

  @[Export(range: 0..512, step: 1)]
  property padding : Int64 = DEFAULT_PADDING.to_i64

  @[Export(range: 0..2048, step: 1)]
  property cell_px_size : Int64 = LETTER_GLYPHS_CONFIG.cell_px_size.to_i64

  @[ExportToolButton("Rebuild Spritesheet", icon: "Reload")]
  def rebuild_spritesheet : Void
    res = SvgSpritesheetBuilder.generate(
      source_dir: source_dir,
      output_path: output_path,
      resource_path: resource_path,
      strip_prefix: strip_prefix,
      atlas_name: atlas_name,
      columns: columns.to_i32,
      icon_size: icon_size.to_i32,
      padding: padding.to_i32,
      cell_px_size: cell_px_size.to_i32
    )
    Godot.print("[SvgSpritesheetBuilder] Built #{res.output_path} (#{res.count} icons, #{res.columns}x#{res.rows} grid, #{res.cell_px_size}x#{res.cell_px_size}px per cell)")
  rescue ex
    Godot.printerr("[SvgSpritesheetBuilder] Failed to build spritesheet: #{ex.message}")
  end

  @[ExportToolButton("Rebuild All Preset Spritesheets", icon: "Reload")]
  def rebuild_all_spritesheets : Void
    results = SvgSpritesheetBuilder.generate_all
    results.each do |res|
      Godot.print("[SvgSpritesheetBuilder] Built #{res.output_path} (#{res.count} icons, #{res.columns}x#{res.rows} grid, #{res.cell_px_size}x#{res.cell_px_size}px per cell)")
    end
  rescue ex
    Godot.printerr("[SvgSpritesheetBuilder] Failed to build preset spritesheets: #{ex.message}")
  end

  # Normalizes a single FontAwesome SVG string so that any `<path>` with `opacity`
  # (transparent secondary duotone layer) has its `opacity` removed and its fill
  # changed to solid white (`#ffffff`), while keeping primary black paths (`fill="currentColor"`) black.
  def self.normalize_svg(svg_content : String) : String
    svg_content.gsub(/<path\b([^>]*?)\bopacity="[^"]*"([^>]*?)\/>/) do |_match|
      attrs = "#{$1}#{$2}"
      if attrs.includes?("fill=")
        attrs = attrs.gsub(/\bfill="[^"]*"/, %(fill="#ffffff"))
      else
        attrs = %( fill="#ffffff"#{attrs})
      end
      normalized_attrs = attrs.gsub(/\s+/, " ").strip
      "<path #{normalized_attrs}/>"
    end
  end

  # Extracts all `<path .../>` elements from a normalized SVG string.
  def self.extract_paths(svg_content : String) : Array(String)
    normalized = normalize_svg(svg_content)
    paths = [] of String
    normalized.scan(/<path\b[^>]*\/>/) do |match|
      paths << match[0]
    end
    paths
  end

  # Generates a combined SVG spritesheet and `.tres` `SpritesheetAtlas` resource from a `Config`.
  def self.generate(config : Config) : Result
    generate(
      source_dir: config.source_dir,
      output_path: config.output_path,
      resource_path: config.resource_path,
      strip_prefix: config.strip_prefix,
      atlas_name: config.name,
      title: config.title,
      columns: config.columns,
      icon_size: config.icon_size,
      padding: config.padding,
      cell_px_size: config.cell_px_size,
      aliases: config.aliases
    )
  end

  # Generates all registered preset spritesheets (`FACES_CONFIG` and `LETTER_GLYPHS_CONFIG`).
  def self.generate_all : Array(Result)
    PRESETS.map { |cfg| generate(cfg) }
  end

  # Scans `source_dir` for all `.svg` files, normalizes each file in-place if needed,
  # writes the combined padded spritesheet to `output_path`, and writes the `.tres`
  # `SpritesheetAtlas` resource to `resource_path` when provided.
  def self.generate(
    source_dir : String,
    output_path : String,
    resource_path : String = "",
    strip_prefix : String = "",
    atlas_name : String = "",
    title : String = "",
    columns : Int32 = DEFAULT_COLUMNS,
    icon_size : Int32 = DEFAULT_ICON_SIZE,
    padding : Int32 = DEFAULT_PADDING,
    cell_px_size : Int32 = DEFAULT_CELL_PX_SIZE,
    aliases : Hash(String, String) = Hash(String, String).new
  ) : Result
    resolved_dir = resolve_filesystem_path(source_dir)
    resolved_out = resolve_filesystem_path(output_path)

    unless Dir.exists?(resolved_dir)
      raise "Spritesheet source directory not found: #{resolved_dir}"
    end

    svg_files = Dir.children(resolved_dir)
      .select { |name| name.downcase.ends_with?(".svg") }
      .sort!

    cols = Math.max(columns, 1)
    count = svg_files.size
    rows = count > 0 ? ((count + cols - 1) // cols) : 1
    cell_size = icon_size + (padding * 2)
    px_per_cell = cell_px_size > 0 ? cell_px_size : (cell_size // 2)
    vb_width = cols * cell_size
    vb_height = rows * cell_size
    px_width = cols * px_per_cell
    px_height = rows * px_per_cell

    effective_name = atlas_name.empty? ? File.basename(output_path, ".svg") : atlas_name
    effective_title = title.empty? ? effective_name.split(/[_-]/).map(&.capitalize).join(" ") : title
    item_ids = Array(String).new(count)

    svg_out = String.build do |io|
      io << %(<svg xmlns="http://www.w3.org/2000/svg" width="#{px_width}" height="#{px_height}" viewBox="0 0 #{vb_width} #{vb_height}">\n)
      io << %(  <!--! Font Awesome Pro 7.1.0 #{effective_title} Spritesheet (#{cols}x#{rows} grid, #{cell_size}x#{cell_size} viewBox cells with #{padding}-unit padding, #{px_per_cell}x#{px_per_cell}px per cell) -->\n)

      svg_files.each_with_index do |filename, idx|
        full_path = File.join(resolved_dir, filename)
        raw_content = File.read(full_path)
        normalized_content = normalize_svg(raw_content)
        if normalized_content != raw_content
          File.write(full_path, normalized_content)
        end

        id = File.basename(filename, ".svg")
        item_ids << id
        col = idx % cols
        row = idx // cols
        tx = col * cell_size + padding
        ty = row * cell_size + padding

        io << %(  <g id="#{id}" transform="translate(#{tx},#{ty})">\n)
        extract_paths(normalized_content).each do |path_tag|
          io << "    " << path_tag << "\n"
        end
        io << "  </g>\n"
      end

      io << "</svg>\n"
    end

    out_dir = File.dirname(resolved_out)
    Dir.mkdir_p(out_dir) unless Dir.exists?(out_dir)
    File.write(resolved_out, svg_out)

    ensure_lossless_svg_import(resolved_out, to_res_path(output_path))

    eff_res_path = if !resource_path.empty?
                     resource_path
                   elsif output_path.downcase.ends_with?(".svg")
                     output_path[0...-4] + ".tres"
                   else
                     ""
                   end

    atlas = SpritesheetAtlas.new
    atlas.configure(
      atlas_name: effective_name,
      source_dir: to_res_path(source_dir),
      texture_path: to_res_path(output_path),
      resource_path: eff_res_path.empty? ? "" : to_res_path(eff_res_path),
      strip_prefix: strip_prefix,
      columns: cols,
      rows: rows,
      icon_size: icon_size,
      padding: padding,
      cell_px_size: px_per_cell,
      item_ids: item_ids,
      aliases: aliases
    )

    resolved_res_out = ""
    unless eff_res_path.empty?
      resolved_res_out = resolve_filesystem_path(eff_res_path)
      write_tres_resource(resolved_res_out, atlas)
    end

    # Sync static registry modules when rebuilding faces or letter_glyphs
    case effective_name
    when Faces::ATLAS_NAME
      Faces.resource = atlas
    when Glyphs::ATLAS_NAME
      Glyphs.resource = atlas
    end

    # Trigger Godot Editor filesystem scan if running inside the editor
    if Godot.editor_hint? && !Godot::EditorInterface.singleton_ptr.null?
      ei = Godot::EditorInterface.new(Godot::EditorInterface.singleton_ptr)
      r_fs = ei.get_resource_filesystem
      if !r_fs.pointer.null?
        r_fs.scan rescue nil
      end
    end

    Result.new(
      count: count,
      columns: cols,
      rows: rows,
      output_path: resolved_out,
      resource_path: resolved_res_out,
      item_ids: atlas.item_ids,
      item_keys: atlas.item_keys,
      atlas: atlas,
      cell_px_size: px_per_cell
    )
  end

  # Writes a Godot 4 `.tres` resource file for `SpritesheetAtlas`.
  def self.write_tres_resource(resolved_tres_path : String, atlas : SpritesheetAtlas) : Void
    tres_dir = File.dirname(resolved_tres_path)
    Dir.mkdir_p(tres_dir) unless Dir.exists?(tres_dir)

    content = String.build do |io|
      io << %([gd_resource type="SpritesheetAtlas" format=3]\n\n)
      io << %([ext_resource type="Script" path="res://addons/pattern_material/src/resources/spritesheet_atlas.cr" id="1_script"]\n\n)
      io << %([resource]\n)
      io << %(script = ExtResource("1_script")\n)
      io << %(atlas_name = #{atlas.atlas_name.inspect}\n)
      io << %(source_dir = #{atlas.source_dir.inspect}\n)
      io << %(texture_path = #{atlas.texture_path.inspect}\n)
      io << %(strip_prefix = #{atlas.strip_prefix.inspect}\n)
      io << %(columns = #{atlas.columns}\n)
      io << %(rows = #{atlas.rows}\n)
      io << %(count = #{atlas.count}\n)
      io << %(icon_size = #{atlas.icon_size}\n)
      io << %(padding = #{atlas.padding}\n)
      io << %(cell_px_size = #{atlas.cell_px_size}\n)
      io << %(item_ids_csv = #{atlas.item_ids_csv.inspect}\n)
      io << %(item_keys_csv = #{atlas.item_keys_csv.inspect}\n)
    end

    File.write(resolved_tres_path, content)
  end

  # Ensures `<output_svg>.import` exists with lossless compression (`compress/mode=0`, `detect_3d/compress_to=0`)
  # so Godot does not apply lossy VRAM compression to the SVG spritesheet.
  def self.ensure_lossless_svg_import(resolved_svg_path : String, res_svg_path : String) : Void
    import_path = "#{resolved_svg_path}.import"
    return if File.exists?(import_path)

    content = <<-IMPORT
    [remap]

    importer="texture"
    type="CompressedTexture2D"
    metadata={
    "vram_texture": false
    }

    [deps]

    source_file="#{res_svg_path}"

    [params]

    compress/mode=0
    compress/high_quality=false
    compress/high_quality_mode=0
    compress/lossy_quality=0.7
    compress/uastc_level=0
    compress/rdo_quality_loss=0.0
    compress/hdr_compression=1
    compress/normal_map=0
    compress/channel_pack=0
    mipmaps/generate=true
    mipmaps/limit=-1
    mipmaps/preserve_alpha_test_coverage=false
    mipmaps/alpha_test_threshold=0.5
    roughness/mode=0
    roughness/src_normal=""
    process/channel_remap/red=0
    process/channel_remap/green=1
    process/channel_remap/blue=2
    process/channel_remap/alpha=3
    process/fix_alpha_border=true
    process/premult_alpha=false
    process/normal_map_invert_y=false
    process/hdr_as_srgb=false
    process/hdr_clamp_exposure=false
    process/size_limit=0
    detect_3d/compress_to=0
    svg/scale=1.0
    editor/scale_with_editor_scale=false
    editor/convert_colors_with_editor_theme=false
    IMPORT

    File.write(import_path, content + "\n")
  end

  def self.to_res_path(path : String) : String
    normalized = path.gsub('\\', '/')
    return normalized if normalized.starts_with?("res://")
    "res://#{normalized.lstrip('/')}"
  end

  def self.resolve_filesystem_path(path : String) : String
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
