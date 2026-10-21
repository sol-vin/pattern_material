require "lapis"
require "./spritesheet_atlas"

include Godot

# Shared lookup and metadata interface for static spritesheet modules (`Faces`, `Glyphs`).
module SpritesheetRegistryModule
  abstract def resource : SpritesheetAtlas

  def [](key : String | Char) : Int32
    resource[key]
  end

  def [](key : Symbol) : Int32
    resource[key]
  end

  def []?(key : String | Char) : Int32?
    resource[key]?
  end

  def []?(key : Symbol) : Int32?
    resource[key]?
  end

  def has?(key : String | Char | Symbol) : Bool
    resource.has?(key)
  end

  def info(key : String | Char | Symbol) : SpritesheetAtlas::ItemInfo
    resource.info(key)
  end

  def info?(key : String | Char | Symbol) : SpritesheetAtlas::ItemInfo?
    resource.info?(key)
  end

  def info_at(index : Int) : SpritesheetAtlas::ItemInfo
    resource.info_at(index)
  end

  def info_at?(index : Int) : SpritesheetAtlas::ItemInfo?
    resource.info_at?(index)
  end

  def key_at(index : Int) : String
    resource.key_at(index)
  end

  def key_at?(index : Int) : String?
    resource.key_at?(index)
  end

  def id_at(index : Int) : String
    resource.id_at(index)
  end

  def id_at?(index : Int) : String?
    resource.id_at?(index)
  end

  def keys : Array(String)
    resource.keys
  end

  def ids : Array(String)
    resource.ids
  end

  def entries : Array(SpritesheetAtlas::ItemInfo)
    resource.entries
  end

  def hframes : Int32
    resource.hframes
  end

  def vframes : Int32
    resource.vframes
  end

  def columns : Int32
    resource.hframes
  end

  def rows : Int32
    resource.vframes
  end

  def count : Int32
    resource.size
  end

  def size : Int32
    resource.size
  end

  def icon_size : Int32
    resource.icon_size.to_i32
  end

  def padding : Int32
    resource.padding.to_i32
  end

  def cell_size : Int32
    resource.cell_size
  end

  def cell_px_size : Int32
    resource.effective_cell_px_size
  end

  def source_dir : String
    resource.source_dir
  end

  def texture_path : String
    resource.texture_path
  end

  def resource_path : String
    resource.resource_path
  end

  def strip_prefix : String
    resource.strip_prefix
  end

  def texture : Texture2D?
    resource.texture
  end

  def apply_to(material : ShaderMaterial, key : String | Char | Symbol) : Int32
    resource.apply_to(material, key)
  end
end

# Static lookup module and `SpritesheetAtlas` holder for `res://textures/fontawesome/faces.svg`.
#
# Examples:
# ```
# Faces["smile"]       # => 86
# Faces["happy"]       # => 86
# Faces["angry-horns"] # => 0
# Faces.info("smile")  # => SpritesheetAtlas::ItemInfo(index: 86, id: "face-smile", key: "smile", ...)
# ```
module Faces
  extend SpritesheetRegistryModule

  ATLAS_NAME    = "faces"
  SOURCE_DIR    = "res://textures/fontawesome/faces"
  TEXTURE_PATH  = "res://textures/fontawesome/faces.svg"
  RESOURCE_PATH = "res://textures/fontawesome/faces.tres"
  STRIP_PREFIX  = "face-"
  DEFAULT_COLS  =  12
  ICON_SIZE     = 640
  PADDING       =  64
  CELL_PX_SIZE  = 384

  ALIASES = {
    "happy" => "smile",
  }

  DEFAULT_IDS = [
    "face-angry-horns",
    "face-angry",
    "face-anguished",
    "face-anxious-sweat",
    "face-astonished",
    "face-awesome",
    "face-back",
    "face-beam-hand-over-mouth",
    "face-confounded",
    "face-confused",
    "face-diagonal-mouth",
    "face-disappointed",
    "face-disguise",
    "face-dizzy",
    "face-dotted",
    "face-downcast-sweat",
    "face-drooling",
    "face-expressionless",
    "face-eyes-xmarks",
    "face-fearful",
    "face-flushed",
    "face-frown-open",
    "face-frown-slight",
    "face-frown",
    "face-glasses",
    "face-grimace",
    "face-grin-beam-sweat",
    "face-grin-beam",
    "face-grin-hearts",
    "face-grin-squint-tears",
    "face-grin-squint",
    "face-grin-stars",
    "face-grin-tears",
    "face-grin-tongue-squint",
    "face-grin-tongue-wink",
    "face-grin-tongue",
    "face-grin-wide",
    "face-grin-wink",
    "face-grin",
    "face-hand-over-mouth",
    "face-head-bandage",
    "face-holding-back-tears",
    "face-hushed",
    "face-icicles",
    "face-kiss-beam",
    "face-kiss-closed-eyes",
    "face-kiss-wink-heart",
    "face-kiss",
    "face-laugh-beam",
    "face-laugh-squint",
    "face-laugh-wink",
    "face-laugh",
    "face-lying",
    "face-mask",
    "face-meh-blank",
    "face-meh",
    "face-melting",
    "face-monocle",
    "face-nauseated",
    "face-party",
    "face-pensive",
    "face-persevering",
    "face-pleading",
    "face-pouting",
    "face-raised-eyebrow",
    "face-relieved",
    "face-rolling-eyes",
    "face-sad-cry",
    "face-sad-sweat",
    "face-sad-tear",
    "face-saluting",
    "face-shaking-horizontal",
    "face-shaking-vertical",
    "face-shaking",
    "face-shush",
    "face-sleeping",
    "face-sleepy",
    "face-smile-beam",
    "face-smile-halo",
    "face-smile-hearts",
    "face-smile-horns",
    "face-smile-relaxed",
    "face-smile-tear",
    "face-smile-tongue",
    "face-smile-upside-down",
    "face-smile-wink",
    "face-smile",
    "face-smirking",
    "face-spiral-eyes",
    "face-sunglasses",
    "face-surprise",
    "face-swear",
    "face-thermometer",
    "face-thinking",
    "face-tired",
    "face-tissue",
    "face-tongue-money",
    "face-tongue-sweat",
    "face-unamused",
    "face-vomit",
    "face-weary",
    "face-woozy",
    "face-worried",
    "face-zany",
    "face-zipper",
  ]

  @@atlas : SpritesheetAtlas? = nil

  def self.resource : SpritesheetAtlas
    if current = @@atlas
      return current
    end
    atlas = SpritesheetAtlas.new
    rows = (DEFAULT_IDS.size + DEFAULT_COLS - 1) // DEFAULT_COLS
    atlas.configure(
      atlas_name: ATLAS_NAME,
      source_dir: SOURCE_DIR,
      texture_path: TEXTURE_PATH,
      resource_path: RESOURCE_PATH,
      strip_prefix: STRIP_PREFIX,
      columns: DEFAULT_COLS,
      rows: rows,
      icon_size: ICON_SIZE,
      padding: PADDING,
      cell_px_size: CELL_PX_SIZE,
      item_ids: DEFAULT_IDS,
      aliases: ALIASES
    )
    @@atlas = atlas
    atlas
  end

  def self.resource=(atlas : SpritesheetAtlas) : SpritesheetAtlas
    ALIASES.each { |k, v| atlas.register_alias(k, v) }
    @@atlas = atlas
  end
end

# Static lookup module and `SpritesheetAtlas` holder for `res://textures/fontawesome/letter_glyphs.svg`.
# Uses explicit variant prefixes (`circle-*`, `square-*`, `circle`, `square`) and 24x24px cells.
#
# Examples:
# ```
# Glyphs["circle-0"] # => 0
# Glyphs["circle-a"] # => 10
# Glyphs["square-0"] # => 162
# Glyphs["square-a"] # => 172
# Glyphs.info("circle-a")
# ```
module Glyphs
  extend SpritesheetRegistryModule

  ATLAS_NAME    = "letter_glyphs"
  SOURCE_DIR    = "res://textures/fontawesome/letter_glyphs"
  TEXTURE_PATH  = "res://textures/fontawesome/letter_glyphs.svg"
  RESOURCE_PATH = "res://textures/fontawesome/letter_glyphs.tres"
  STRIP_PREFIX  = ""
  DEFAULT_COLS  =  12
  ICON_SIZE     = 640
  PADDING       =  64
  CELL_PX_SIZE  =  24

  DEFAULT_IDS = [
    "circle-0",
    "circle-1",
    "circle-2",
    "circle-3",
    "circle-4",
    "circle-5",
    "circle-6",
    "circle-7",
    "circle-8",
    "circle-9",
    "circle-a",
    "circle-ampersand",
    "circle-arrow-up-left",
    "circle-arrow-up",
    "circle-austral",
    "circle-australian-dollar",
    "circle-b",
    "circle-baht",
    "circle-bangladeshi-taka",
    "circle-bitcoin",
    "circle-bolt",
    "circle-book-open",
    "circle-bookmark",
    "circle-brazilian-real",
    "circle-c",
    "circle-calendar",
    "circle-camera",
    "circle-caret-up",
    "circle-cedi",
    "circle-cent",
    "circle-check",
    "circle-chevron-up",
    "circle-chf",
    "circle-colon",
    "circle-cruzeiro",
    "circle-currency",
    "circle-d",
    "circle-danish-krone",
    "circle-divide",
    "circle-dollar",
    "circle-dong",
    "circle-dot",
    "circle-down-left",
    "circle-down-right",
    "circle-down",
    "circle-e",
    "circle-ellipsis-vertical",
    "circle-ellipsis",
    "circle-envelope",
    "circle-equals",
    "circle-euro",
    "circle-eurozone",
    "circle-exclamation",
    "circle-f",
    "circle-florin",
    "circle-franc",
    "circle-g",
    "circle-gf",
    "circle-guarani",
    "circle-h",
    "circle-half-horizontal",
    "circle-half-stroke-horizontal",
    "circle-half-stroke",
    "circle-half",
    "circle-heart",
    "circle-house",
    "circle-hryvnia",
    "circle-i",
    "circle-indian-rupee",
    "circle-info",
    "circle-j",
    "circle-k",
    "circle-kip",
    "circle-l",
    "circle-lari",
    "circle-left",
    "circle-lira",
    "circle-litecoin",
    "circle-location-arrow",
    "circle-m",
    "circle-malaysian-ringgit",
    "circle-manat",
    "circle-microphone-lines",
    "circle-microphone",
    "circle-mill",
    "circle-minus",
    "circle-moon",
    "circle-n",
    "circle-naira",
    "circle-norwegian-krone",
    "circle-o",
    "circle-p",
    "circle-parking",
    "circle-pause",
    "circle-peruvian-soles",
    "circle-peseta",
    "circle-peso",
    "circle-phone-flip",
    "circle-phone-hangup",
    "circle-phone",
    "circle-play",
    "circle-plus",
    "circle-polish-zloty",
    "circle-q",
    "circle-quarter-stroke",
    "circle-quarter",
    "circle-quarters",
    "circle-question",
    "circle-r",
    "circle-radiation",
    "circle-renminbi",
    "circle-right",
    "circle-ruble",
    "circle-rupee",
    "circle-rupiah",
    "circle-s",
    "circle-share-nodes",
    "circle-shekel",
    "circle-small",
    "circle-sort-down",
    "circle-sort-up",
    "circle-sort",
    "circle-star",
    "circle-sterling",
    "circle-stop",
    "circle-swedish-krona",
    "circle-t",
    "circle-tenge",
    "circle-three-quarters-stroke",
    "circle-three-quarters",
    "circle-trash",
    "circle-tugrik",
    "circle-turkish-lira",
    "circle-u",
    "circle-up-left",
    "circle-up-right",
    "circle-up",
    "circle-user-circle-check",
    "circle-user-circle-exclamation",
    "circle-user-circle-minus",
    "circle-user-circle-moon",
    "circle-user-circle-plus",
    "circle-user-circle-question",
    "circle-user-circle-user",
    "circle-user-circle-xmark",
    "circle-user-clock",
    "circle-user",
    "circle-v",
    "circle-video",
    "circle-w",
    "circle-waveform-lines",
    "circle-wifi",
    "circle-won",
    "circle-x",
    "circle-xmark",
    "circle-y",
    "circle-yen",
    "circle-z",
    "circle",
    "circleapore-dollar",
    "circles-overlap-3",
    "circles-overlap",
    "square-0",
    "square-1",
    "square-2",
    "square-3",
    "square-4",
    "square-5",
    "square-6",
    "square-7",
    "square-8",
    "square-9",
    "square-a",
    "square-ampersand",
    "square-arrow-up-right",
    "square-arrow-up",
    "square-austral",
    "square-australian-dollar",
    "square-b",
    "square-baht",
    "square-bangladeshi-taka",
    "square-binary",
    "square-bitcoin",
    "square-bolt",
    "square-brazilian-real",
    "square-c",
    "square-caret-up",
    "square-cedi",
    "square-cent",
    "square-check",
    "square-chevron-up",
    "square-chf",
    "square-code",
    "square-colon",
    "square-cruzeiro",
    "square-currency",
    "square-d",
    "square-danish-krone",
    "square-divide",
    "square-dollar",
    "square-dong",
    "square-down-left",
    "square-down-right",
    "square-down",
    "square-e",
    "square-ellipsis-vertical",
    "square-ellipsis",
    "square-envelope",
    "square-equals",
    "square-euro",
    "square-eurozone",
    "square-exclamation",
    "square-f",
    "square-florin",
    "square-fragile",
    "square-franc",
    "square-g",
    "square-guarani",
    "square-h",
    "square-half-horizontal",
    "square-half-stroke-horizontal",
    "square-half-stroke",
    "square-half",
    "square-heart",
    "square-hryvnia",
    "square-i",
    "square-indian-rupee",
    "square-info",
    "square-j",
    "square-k",
    "square-kanban",
    "square-kip",
    "square-l",
    "square-lari",
    "square-left",
    "square-lira",
    "square-list",
    "square-litecoin",
    "square-m",
    "square-malaysian-ringgit",
    "square-manat",
    "square-microphone",
    "square-mill",
    "square-minus",
    "square-n",
    "square-naira",
    "square-nfi",
    "square-norwegian-krone",
    "square-o",
    "square-p",
    "square-parking",
    "square-pen",
    "square-person-confined",
    "square-peruvian-soles",
    "square-peseta",
    "square-peso",
    "square-phone-flip",
    "square-phone-hangup",
    "square-phone",
    "square-plus",
    "square-polish-zloty",
    "square-poll-horizontal",
    "square-poll-vertical",
    "square-q",
    "square-quarters",
    "square-question",
    "square-quote",
    "square-r",
    "square-renminbi",
    "square-right",
    "square-ring",
    "square-rss",
    "square-ruble",
    "square-rupee",
    "square-rupiah",
    "square-s",
    "square-share-nodes",
    "square-shekel",
    "square-sliders-vertical",
    "square-sliders",
    "square-small",
    "square-star",
    "square-sterling",
    "square-swedish-krona",
    "square-t",
    "square-tenge",
    "square-terminal",
    "square-this-way-up",
    "square-tugrik",
    "square-turkish-lira",
    "square-u",
    "square-up-left",
    "square-up-right",
    "square-up",
    "square-user",
    "square-v",
    "square-virus",
    "square-w",
    "square-wine-glass-crack",
    "square-won",
    "square-x",
    "square-xmark",
    "square-y",
    "square-yen",
    "square-z",
    "square",
    "squareapore-dollar",
  ]

  @@atlas : SpritesheetAtlas? = nil

  def self.resource : SpritesheetAtlas
    if current = @@atlas
      return current
    end
    atlas = SpritesheetAtlas.new
    rows = (DEFAULT_IDS.size + DEFAULT_COLS - 1) // DEFAULT_COLS
    atlas.configure(
      atlas_name: ATLAS_NAME,
      source_dir: SOURCE_DIR,
      texture_path: TEXTURE_PATH,
      resource_path: RESOURCE_PATH,
      strip_prefix: STRIP_PREFIX,
      columns: DEFAULT_COLS,
      rows: rows,
      icon_size: ICON_SIZE,
      padding: PADDING,
      cell_px_size: CELL_PX_SIZE,
      item_ids: DEFAULT_IDS
    )
    @@atlas = atlas
    atlas
  end

  def self.resource=(atlas : SpritesheetAtlas) : SpritesheetAtlas
    @@atlas = atlas
  end
end

alias LetterGlyphs = Glyphs
