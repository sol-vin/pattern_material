require "lapis"

include Godot

# Static 32-color Afterlife 98 palette registry backed by `palette.pal` and `palette.tres`.
#
# Provides O(1) indexed, enum, and named access to all 32 palette colors as `Godot::Color`,
# plus helpers to apply foreground, background, outline, and unreplaced colors to `ShaderMaterial`.
module Palette
  PAL_PATH  = "res://palette.pal"
  TRES_PATH = "res://palette.tres"

  # Strongly-typed 32-color enum suitable for `@[ExportEnum(Palette::ColorId)]` in the Godot Inspector.
  enum ColorId
    DeepIndigo     =  0
    DuskPurple     =  1
    MutedViolet    =  2
    SoftPeriwinkle =  3
    PaleLilac      =  4
    White          =  5
    HoneydewMint   =  6
    Seafoam        =  7
    Teal           =  8
    DeepCerulean   =  9
    CyanLagoon     = 10
    IceAqua        = 11
    SageGray       = 12
    DryMoss        = 13
    WarmCream      = 14
    PeachSorbet    = 15
    ApricotCoral   = 16
    SalmonPink     = 17
    HotWatermelon  = 18
    PlumRose       = 19
    DustyMauve     = 20
    RoseQuartz     = 21
    PaleBlush      = 22
    CornflowerBlue = 23
    SkyAzure       = 24
    BabyBlue       = 25
    LavenderMist   = 26
    OrchidViolet   = 27
    Amethyst       = 28
    BubblegumPink  = 29
    CottonCandy    = 30
    SnowRose       = 31
  end

  # Raw 8-bit RGB triplets from `palette.pal` (32 colors, indices 0..31).
  RGB8_TABLE = [
    {47_u8, 37_u8, 86_u8},    # 0: deep_indigo
    {88_u8, 76_u8, 132_u8},   # 1: dusk_purple
    {130_u8, 124_u8, 175_u8}, # 2: muted_violet
    {174_u8, 171_u8, 211_u8}, # 3: soft_periwinkle
    {206_u8, 207_u8, 240_u8}, # 4: pale_lilac
    {255_u8, 255_u8, 255_u8}, # 5: pure_white
    {201_u8, 255_u8, 191_u8}, # 6: honeydew_mint
    {120_u8, 216_u8, 183_u8}, # 7: seafoam
    {52_u8, 173_u8, 161_u8},  # 8: teal
    {37_u8, 125_u8, 155_u8},  # 9: deep_cerulean
    {37_u8, 188_u8, 198_u8},  # 10: cyan_lagoon
    {160_u8, 255_u8, 240_u8}, # 11: ice_aqua
    {132_u8, 165_u8, 148_u8}, # 12: sage_gray
    {207_u8, 211_u8, 175_u8}, # 13: dry_moss
    {255_u8, 242_u8, 209_u8}, # 14: warm_cream
    {255_u8, 217_u8, 174_u8}, # 15: peach_Sorbet
    {255_u8, 165_u8, 130_u8}, # 16: apricot_coral
    {255_u8, 128_u8, 126_u8}, # 17: salmon_pink
    {255_u8, 84_u8, 112_u8},  # 18: hot_watermelon
    {152_u8, 88_u8, 104_u8},  # 19: plum_rose
    {183_u8, 132_u8, 130_u8}, # 20: dusty_mauve
    {221_u8, 164_u8, 159_u8}, # 21: rose_quartz
    {224_u8, 189_u8, 193_u8}, # 22: pale_blush
    {119_u8, 137_u8, 239_u8}, # 23: cornflower_blue
    {94_u8, 193_u8, 255_u8},  # 24: sky_azure
    {186_u8, 230_u8, 255_u8}, # 25: baby_blue
    {226_u8, 211_u8, 255_u8}, # 26: lavender_mist
    {190_u8, 155_u8, 255_u8}, # 27: orchid_violet
    {153_u8, 104_u8, 226_u8}, # 28: amethyst
    {255_u8, 155_u8, 182_u8}, # 29: bubblegum_pink
    {255_u8, 204_u8, 220_u8}, # 30: cotton_candy
    {255_u8, 234_u8, 246_u8}, # 31: snow_rose
  ]

  NAMES = [
    "deep_indigo",
    "dusk_purple",
    "muted_violet",
    "soft_periwinkle",
    "pale_lilac",
    "white",
    "honeydew_mint",
    "seafoam",
    "teal",
    "deep_cerulean",
    "cyan_lagoon",
    "ice_aqua",
    "sage_gray",
    "dry_moss",
    "warm_cream",
    "peach_sorbet",
    "apricot_coral",
    "salmon_pink",
    "hot_watermelon",
    "plum_rose",
    "dusty_mauve",
    "rose_quartz",
    "pale_blush",
    "cornflower_blue",
    "sky_azure",
    "baby_blue",
    "lavender_mist",
    "orchid_violet",
    "amethyst",
    "bubblegum_pink",
    "cotton_candy",
    "snow_rose",
  ]

  @@colors : Array(Color)? = nil
  @@name_lookup : Hash(String, Int32)? = nil

  def self.count : Int32
    RGB8_TABLE.size
  end

  def self.size : Int32
    RGB8_TABLE.size
  end

  def self.names : Array(String)
    NAMES
  end

  # Returns all 32 `Godot::Color` entries in palette order.
  def self.colors : Array(Color)
    if existing = @@colors
      return existing
    end
    built = RGB8_TABLE.map do |r, g, b|
      Color.new(r.to_f32 / 255.0_f32, g.to_f32 / 255.0_f32, b.to_f32 / 255.0_f32, 1.0_f32)
    end
    @@colors = built
    built
  end

  # Returns the `Godot::Color` at 0-based `index` (`0..31`), raising `IndexError` if out of bounds.
  def self.at(index : Int) : Color
    colors[index.to_i32]? || raise IndexError.new("Palette index #{index} out of bounds (0...#{size})")
  end

  def self.at?(index : Int) : Color?
    colors[index.to_i32]?
  end

  # Looks up a palette index (`0..31`) by semantic color name.
  def self.index?(name : String | Symbol) : Int32?
    norm = name.to_s.strip.downcase.gsub('-', '_').gsub(' ', '_')
    name_table[norm]?
  end

  def self.index(name : String | Symbol) : Int32
    index?(name) || raise KeyError.new("Unknown palette color name '#{name}'")
  end

  def self.[](index : Int) : Color
    at(index)
  end

  def self.[]?(index : Int) : Color?
    at?(index)
  end

  def self.[](id : ColorId) : Color
    at(id.value)
  end

  def self.[]?(id : ColorId) : Color?
    at?(id.value)
  end

  def self.[](name : String | Symbol) : Color
    at(index(name))
  end

  def self.[]?(name : String | Symbol) : Color?
    if idx = index?(name)
      at?(idx)
    else
      nil
    end
  end

  # Resolves a `ColorId`, `Int`, `String`, `Symbol`, or `Color` into a `Godot::Color`.
  def self.resolve(col : ColorId | Int | String | Symbol | Color) : Color
    case col
    when Color
      col
    when ColorId
      at(col.value)
    when Int
      at(col)
    when String, Symbol
      self[col]
    else
      at(0)
    end
  end

  # Applies palette colors (`fg_color`, `bg_color`, and optionally `outline_color` and `unreplaced_color`)
  # onto a `ShaderMaterial` using `pattern_replace.gdshader`.
  def self.apply_to(
    material : ShaderMaterial,
    fg : ColorId | Int | String | Symbol | Color,
    bg : ColorId | Int | String | Symbol | Color,
    outline : (ColorId | Int | String | Symbol | Color)? = nil,
    unreplaced : (ColorId | Int | String | Symbol | Color)? = nil
  ) : Void
    fg_col = resolve(fg)
    bg_col = resolve(bg)
    out_col = outline ? resolve(outline) : nil
    unrep_col = unreplaced ? resolve(unreplaced) : nil

    if !material.pointer.null?
      material.call("set_shader_parameter", "fg_color", fg_col)
      material.call("set_shader_parameter", "bg_color", bg_col)
      if oc = out_col
        material.call("set_shader_parameter", "outline_color", oc)
      end
      if uc = unrep_col
        material.call("set_shader_parameter", "remap_unreplaced", true)
        material.call("set_shader_parameter", "unreplaced_color", uc)
      end
    end
  end

  private def self.name_table : Hash(String, Int32)
    if existing = @@name_lookup
      return existing
    end
    table = Hash(String, Int32).new(initial_capacity: NAMES.size + 4)
    NAMES.each_with_index do |n, idx|
      table[n] = idx
    end
    table["pure_white"] = 5
    table["indigo"] = 0
    table["mint"] = 6
    table["coral"] = 16
    table["watermelon"] = 18
    @@name_lookup = table
    table
  end
end
