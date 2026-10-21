require "lapis"
require "../generators/generators"

include Godot

# Static lookup registry for all 88 black-and-white repeating SVG patterns in
# `res://addons/pattern_material/textures/patterns/*.svg`, plus factory helpers
# for procedural `PatternGenerator` textures.
#
# Examples:
# ```
# Patterns["moroccan"]                  # => "res://addons/pattern_material/textures/patterns/moroccan.svg"
# Patterns["zig-zag"]                   # => "res://addons/pattern_material/textures/patterns/zig_zag.svg"
# Patterns.index("hexagons")            # => 40
# Patterns.texture("topography")        # => Texture2D? (when running inside Godot)
# Patterns.apply_to(material, "groovy") # sets `custom_pattern` shader parameter
# Patterns.polka_dots(dot_radius: 14.0) # => PolkaDotPattern < PatternGenerator < ImageTexture
# ```
module Patterns
  SOURCE_DIR        = "res://addons/pattern_material/textures/patterns"
  LEGACY_SOURCE_DIR = "res://textures/patterns"

  DEFAULT_IDS = [
    "4_point_stars",
    "anchors_away",
    "architect",
    "autumn",
    "aztec",
    "bamboo",
    "bank_note",
    "bathroom_floor",
    "bevel_circle",
    "boxes",
    "brick_wall",
    "bubbles",
    "cage",
    "charlie_brown",
    "church_on_sunday",
    "circles_and_squares",
    "circuit_board",
    "connections",
    "cork_screw",
    "current",
    "curtain",
    "cutout",
    "death_star",
    "default_pattern",
    "diagonal_lines",
    "diagonal_stripes",
    "dominos",
    "endless_clouds",
    "eyes",
    "falling_triangles",
    "fancy_rectangles",
    "flipped_diamonds",
    "floating_cogs",
    "floor_tile",
    "formal_invitation",
    "glamorous",
    "graph_paper",
    "groovy",
    "happy_intersection",
    "heavy_rain",
    "hexagons",
    "hideout",
    "houndstooth",
    "i_like_food",
    "intersecting_circles",
    "jigsaw",
    "jupiter",
    "kiwi",
    "leaf",
    "lines_in_motion",
    "lips",
    "lisbon",
    "melt",
    "moroccan",
    "morphing_diamonds",
    "overcast",
    "overlapping_circles",
    "overlapping_diamonds",
    "overlapping_hexagons",
    "parkay_floor",
    "piano_man",
    "pie_factory",
    "pixel_dots",
    "plus",
    "polka_dots",
    "rails",
    "rain",
    "random_shapes",
    "rounded_plus_connected",
    "signal",
    "skulls",
    "slanted_stars",
    "squares",
    "squares_in_squares",
    "stamp_collection",
    "steel_beams",
    "stripes",
    "temple",
    "texture",
    "tic_tac_toe",
    "tiny_checkers",
    "topography",
    "volcano_lamp",
    "wallpaper",
    "wiggle",
    "x_equals",
    "yyy",
    "zig_zag",
  ]

  @@lookup : Hash(String, Int32)? = nil

  def self.ids : Array(String)
    DEFAULT_IDS
  end

  def self.keys : Array(String)
    DEFAULT_IDS
  end

  def self.count : Int32
    DEFAULT_IDS.size
  end

  def self.size : Int32
    DEFAULT_IDS.size
  end

  # Normalizes a pattern lookup key (accepts hyphens, underscores, spaces, or `.svg` suffix).
  def self.normalize_key(key : String | Symbol) : String
    raw = key.to_s.strip.downcase
    raw = raw[0...-4] if raw.ends_with?(".svg")
    if raw.starts_with?("#{SOURCE_DIR}/")
      raw = raw[(SOURCE_DIR.size + 1)..]
    elsif raw.starts_with?("#{LEGACY_SOURCE_DIR}/")
      raw = raw[(LEGACY_SOURCE_DIR.size + 1)..]
    end
    raw.gsub('-', '_').gsub(' ', '_')
  end

  # Looks up the 0-based index of a pattern by key, or returns `nil` if not found.
  def self.index?(key : String | Symbol) : Int32?
    lookup_table[normalize_key(key)]?
  end

  # Looks up the 0-based index of a pattern by key, raising `KeyError` if not found.
  def self.index(key : String | Symbol) : Int32
    index?(key) || raise KeyError.new("Unknown pattern key '#{key}' in Patterns")
  end

  # Returns `true` if `key` exists in `Patterns`.
  def self.has?(key : String | Symbol) : Bool
    !index?(key).nil?
  end

  # Returns the canonical `res://addons/pattern_material/textures/patterns/<id>.svg` path for `key`.
  def self.path(key : String | Symbol) : String
    idx = index(key)
    "#{SOURCE_DIR}/#{DEFAULT_IDS[idx]}.svg"
  end

  def self.path?(key : String | Symbol) : String?
    if idx = index?(key)
      "#{SOURCE_DIR}/#{DEFAULT_IDS[idx]}.svg"
    else
      nil
    end
  end

  def self.path_at(idx : Int) : String
    id = DEFAULT_IDS[idx.to_i32]? || raise IndexError.new("Pattern index #{idx} out of bounds (0...#{size})")
    "#{SOURCE_DIR}/#{id}.svg"
  end

  def self.[](key : String | Symbol) : String
    path(key)
  end

  def self.[]?(key : String | Symbol) : String?
    path?(key)
  end

  def self.[](idx : Int) : String
    path_at(idx)
  end

  # Preloads and returns the `Texture2D` for `key` when running inside Godot.
  def self.texture(key : String | Symbol) : Texture2D?
    res_path = path?(key)
    return nil unless res_path
    Godot.preload?(res_path, Texture2D)
  rescue
    nil
  end

  # Assigns `custom_pattern` on a `ShaderMaterial` using `pattern_replace.gdshader` and returns the resolved resource path.
  def self.apply_to(material : ShaderMaterial, key : String | Symbol) : String
    res_path = path(key)
    if !material.pointer.null?
      if tex = texture(key)
        material.call("set_shader_parameter", "custom_pattern", tex) if !tex.pointer.null?
      end
    end
    res_path
  end

  # Assigns a procedural `PatternGenerator` to `custom_pattern` on a `ShaderMaterial`.
  def self.apply_to(material : ShaderMaterial, generator : PatternGenerator) : PatternGenerator
    generator.apply_to(material)
  end

  # Creates a customized `PolkaDotPattern` procedural texture generator.
  def self.polka_dots(
    dot_radius : Float64 = 18.0,
    columns : Int = 2,
    rows : Int = 2,
    stagger : Bool = true,
    ring_thickness : Float64 = 0.0,
    tile_size : Int = 128,
    invert : Bool = false
  ) : PolkaDotPattern
    gen = PolkaDotPattern.new
    gen.tile_size = tile_size.to_i64
    gen.invert = invert
    gen.dot_radius = dot_radius
    gen.columns = columns.to_i64
    gen.rows = rows.to_i64
    gen.stagger = stagger
    gen.ring_thickness = ring_thickness
    gen
  end

  # Creates a customized `StripePattern` procedural texture generator.
  def self.stripes(
    stripe_count : Int = 4,
    duty_cycle : Float64 = 0.5,
    angle_degrees : Float64 = 0.0,
    crosshatch : Bool = false,
    tile_size : Int = 128,
    invert : Bool = false
  ) : StripePattern
    gen = StripePattern.new
    gen.tile_size = tile_size.to_i64
    gen.invert = invert
    gen.stripe_count = stripe_count.to_i64
    gen.duty_cycle = duty_cycle
    gen.angle_degrees = angle_degrees
    gen.crosshatch = crosshatch
    gen
  end

  # Creates a customized `CheckerPattern` procedural texture generator.
  def self.checkers(
    columns : Int = 2,
    rows : Int = 2,
    cell_inset : Float64 = 0.0,
    corner_radius : Float64 = 0.0,
    tile_size : Int = 128,
    invert : Bool = false
  ) : CheckerPattern
    gen = CheckerPattern.new
    gen.tile_size = tile_size.to_i64
    gen.invert = invert
    gen.columns = columns.to_i64
    gen.rows = rows.to_i64
    gen.cell_inset = cell_inset
    gen.corner_radius = corner_radius
    gen
  end

  # Creates a customized `ZigZagPattern` procedural texture generator.
  def self.zig_zag(
    peaks : Int = 2,
    bands : Int = 2,
    amplitude : Float64 = 20.0,
    thickness : Float64 = 12.0,
    tile_size : Int = 128,
    invert : Bool = false
  ) : ZigZagPattern
    gen = ZigZagPattern.new
    gen.tile_size = tile_size.to_i64
    gen.invert = invert
    gen.peaks = peaks.to_i64
    gen.bands = bands.to_i64
    gen.amplitude = amplitude
    gen.thickness = thickness
    gen
  end

  # Creates a customized `WavePattern` procedural texture generator.
  def self.waves(
    waves : Int = 2,
    bands : Int = 2,
    amplitude : Float64 = 16.0,
    thickness : Float64 = 10.0,
    tile_size : Int = 128,
    invert : Bool = false
  ) : WavePattern
    gen = WavePattern.new
    gen.tile_size = tile_size.to_i64
    gen.invert = invert
    gen.waves = waves.to_i64
    gen.bands = bands.to_i64
    gen.amplitude = amplitude
    gen.thickness = thickness
    gen
  end

  # Creates a customized `RingPattern` procedural texture generator.
  def self.rings(
    ring_count : Int = 3,
    ring_width : Float64 = 8.0,
    max_radius : Float64 = 45.0,
    corner_overlays : Bool = false,
    tile_size : Int = 128,
    invert : Bool = false
  ) : RingPattern
    gen = RingPattern.new
    gen.tile_size = tile_size.to_i64
    gen.invert = invert
    gen.ring_count = ring_count.to_i64
    gen.ring_width = ring_width
    gen.max_radius = max_radius
    gen.corner_overlays = corner_overlays
    gen
  end

  # Creates a customized `HexagonPattern` procedural texture generator.
  def self.hexagons(
    columns : Int = 2,
    rows : Int = 2,
    hex_radius : Float64 = 22.0,
    stroke_width : Float64 = 5.0,
    flat_top : Bool = false,
    tile_size : Int = 128,
    invert : Bool = false
  ) : HexagonPattern
    gen = HexagonPattern.new
    gen.tile_size = tile_size.to_i64
    gen.invert = invert
    gen.columns = columns.to_i64
    gen.rows = rows.to_i64
    gen.hex_radius = hex_radius
    gen.stroke_width = stroke_width
    gen.flat_top = flat_top
    gen
  end

  # Creates a customized `DiamondPattern` procedural texture generator.
  def self.diamonds(
    columns : Int = 2,
    rows : Int = 2,
    diamond_scale : Float64 = 0.85,
    hollow_stroke : Float64 = 0.0,
    tile_size : Int = 128,
    invert : Bool = false
  ) : DiamondPattern
    gen = DiamondPattern.new
    gen.tile_size = tile_size.to_i64
    gen.invert = invert
    gen.columns = columns.to_i64
    gen.rows = rows.to_i64
    gen.diamond_scale = diamond_scale
    gen.hollow_stroke = hollow_stroke
    gen
  end

  # Creates a customized `CrossPattern` procedural texture generator.
  def self.crosses(
    columns : Int = 2,
    rows : Int = 2,
    arm_length : Float64 = 28.0,
    arm_thickness : Float64 = 8.0,
    stagger : Bool = true,
    diagonal_x : Bool = false,
    tile_size : Int = 128,
    invert : Bool = false
  ) : CrossPattern
    gen = CrossPattern.new
    gen.tile_size = tile_size.to_i64
    gen.invert = invert
    gen.columns = columns.to_i64
    gen.rows = rows.to_i64
    gen.arm_length = arm_length
    gen.arm_thickness = arm_thickness
    gen.stagger = stagger
    gen.diagonal_x = diagonal_x
    gen
  end

  # Creates a customized `StarPattern` procedural texture generator.
  def self.stars(
    columns : Int = 2,
    rows : Int = 2,
    points : Int = 4,
    outer_radius : Float64 = 22.0,
    inner_radius : Float64 = 8.0,
    stagger : Bool = true,
    tile_size : Int = 128,
    invert : Bool = false
  ) : StarPattern
    gen = StarPattern.new
    gen.tile_size = tile_size.to_i64
    gen.invert = invert
    gen.columns = columns.to_i64
    gen.rows = rows.to_i64
    gen.points = points.to_i64
    gen.outer_radius = outer_radius
    gen.inner_radius = inner_radius
    gen.stagger = stagger
    gen
  end

  # Creates a customized `BrickPattern` procedural texture generator.
  def self.bricks(
    columns : Int = 2,
    rows : Int = 4,
    mortar_gap : Float64 = 5.0,
    row_offset : Float64 = 0.5,
    corner_radius : Float64 = 2.0,
    tile_size : Int = 128,
    invert : Bool = false
  ) : BrickPattern
    gen = BrickPattern.new
    gen.tile_size = tile_size.to_i64
    gen.invert = invert
    gen.columns = columns.to_i64
    gen.rows = rows.to_i64
    gen.mortar_gap = mortar_gap
    gen.row_offset = row_offset
    gen.corner_radius = corner_radius
    gen
  end

  # Creates a customized `HoundstoothPattern` procedural texture generator.
  def self.houndstooth(
    subdivisions : Int = 2,
    tooth_slant : Float64 = 0.5,
    tile_size : Int = 128,
    invert : Bool = false
  ) : HoundstoothPattern
    gen = HoundstoothPattern.new
    gen.tile_size = tile_size.to_i64
    gen.invert = invert
    gen.subdivisions = subdivisions.to_i64
    gen.tooth_slant = tooth_slant
    gen
  end

  # Creates a customized `HalftonePattern` procedural texture generator.
  def self.halftone(
    columns : Int = 6,
    rows : Int = 6,
    min_radius : Float64 = 2.0,
    max_radius : Float64 = 9.0,
    radial_falloff : Bool = false,
    tile_size : Int = 128,
    invert : Bool = false
  ) : HalftonePattern
    gen = HalftonePattern.new
    gen.tile_size = tile_size.to_i64
    gen.invert = invert
    gen.columns = columns.to_i64
    gen.rows = rows.to_i64
    gen.min_radius = min_radius
    gen.max_radius = max_radius
    gen.radial_falloff = radial_falloff
    gen
  end

  # Creates a multi-mode `CustomPatternGenerator` procedural texture generator.
  def self.custom(
    kind : CustomPatternGenerator::PatternKind = CustomPatternGenerator::PatternKind::PolkaDots,
    columns : Int = 2,
    rows : Int = 2,
    primary_size : Float64 = 18.0,
    secondary_size : Float64 = 6.0,
    stagger : Bool = true,
    tile_size : Int = 128,
    invert : Bool = false
  ) : CustomPatternGenerator
    gen = CustomPatternGenerator.new
    gen.tile_size = tile_size.to_i64
    gen.invert = invert
    gen.kind = kind
    gen.columns = columns.to_i64
    gen.rows = rows.to_i64
    gen.primary_size = primary_size
    gen.secondary_size = secondary_size
    gen.stagger = stagger
    gen
  end

  private def self.lookup_table : Hash(String, Int32)
    if existing = @@lookup
      return existing
    end
    table = Hash(String, Int32).new(initial_capacity: DEFAULT_IDS.size * 2)
    DEFAULT_IDS.each_with_index do |id, idx|
      table[id] = idx
      table[id.gsub('_', '-')] = idx
    end
    @@lookup = table
    table
  end
end
