require "lapis"

include Godot

# Custom Godot Resource representing a packed SVG texture atlas spritesheet
# and providing O(1) lookup of frame indices, grid coordinates, and UV rects
# by `String` or `Char` keys.
@[Tool]
resource SpritesheetAtlas < Resource do
  # Metadata for an individual icon cell inside a `SpritesheetAtlas`.
  struct ItemInfo
    getter index : Int32
    getter id : String
    getter key : String
    getter column : Int32
    getter row : Int32
    getter hframes : Int32
    getter vframes : Int32
    getter uv_rect : Rect2
    getter cell_rect : Rect2

    def initialize(
      @index : Int32,
      @id : String,
      @key : String,
      @column : Int32,
      @row : Int32,
      @hframes : Int32,
      @vframes : Int32,
      @uv_rect : Rect2,
      @cell_rect : Rect2
    )
    end
  end

  @[Export]
  property atlas_name : String = ""

  @[Export]
  property source_dir : String = ""

  @[Export]
  property texture_path : String = ""

  @[Export]
  property strip_prefix : String = ""

  @[Export(range: 1..64, step: 1)]
  property columns : Int64 = 12_i64

  @[Export(range: 1..64, step: 1)]
  property rows : Int64 = 1_i64

  @[Export]
  property count : Int64 = 0_i64

  @[Export(range: 64..2048, step: 1)]
  property icon_size : Int64 = 640_i64

  @[Export(range: 0..512, step: 1)]
  property padding : Int64 = 64_i64

  @[Export(range: 0..2048, step: 1)]
  property cell_px_size : Int64 = 0_i64

  @[Export]
  property item_ids_csv : String = ""

  @[Export]
  property item_keys_csv : String = ""

  @local_resource_path : String = ""
  @item_ids_cache : Array(String)? = nil
  @item_keys_cache : Array(String)? = nil
  @lookup_cache : Hash(String, Int32)? = nil
  @cached_ids_csv : String = ""
  @cached_keys_csv : String = ""
  @aliases : Hash(String, String) = Hash(String, String).new

  # Returns the `.tres` resource path for this atlas, falling back to `Resource#get_path` when backed by Godot.
  def resource_path : String
    if !@local_resource_path.empty?
      @local_resource_path
    elsif !@pointer.null?
      get_path
    else
      ""
    end
  end

  # Sets the `.tres` resource path for this atlas without colliding with `Resource`'s built-in `resource_path` member in ClassDB.
  def resource_path=(val : String)
    @local_resource_path = val
    if !@pointer.null?
      set_path_cache(val) rescue nil
    end
    val
  end

  # Derives the canonical short key from a raw SVG basename `id` and `strip_prefix`.
  def self.derive_key(id : String, strip_prefix : String) : String
    if !strip_prefix.empty? && id.starts_with?(strip_prefix) && id.size > strip_prefix.size
      id[strip_prefix.size..]
    else
      id
    end
  end

  # Normalizes a lookup key (`String` or `Char`) into a canonical lowercase hyphenated string.
  def normalize_key(key : String | Char) : String
    raw = key.to_s.strip.downcase.gsub('_', '-')
    pfx = @strip_prefix.downcase.gsub('_', '-')
    if !pfx.empty? && raw.starts_with?(pfx) && raw.size > pfx.size
      raw[pfx.size..]
    else
      raw
    end
  end

  # Configures all atlas metadata in a single call and rebuilds lookup caches.
  def configure(
    atlas_name : String,
    source_dir : String,
    texture_path : String,
    resource_path : String = "",
    strip_prefix : String = "",
    columns : Int32 = 12,
    rows : Int32 = 1,
    icon_size : Int32 = 640,
    padding : Int32 = 64,
    cell_px_size : Int32 = 0,
    item_ids : Array(String) = [] of String,
    aliases : Hash(String, String)? = nil
  ) : self
    @atlas_name = atlas_name
    @source_dir = source_dir
    @texture_path = texture_path
    self.resource_path = resource_path
    @strip_prefix = strip_prefix
    @columns = Math.max(columns, 1).to_i64
    @rows = Math.max(rows, 1).to_i64
    @count = item_ids.size.to_i64
    @icon_size = icon_size.to_i64
    @padding = padding.to_i64
    @cell_px_size = (cell_px_size > 0 ? cell_px_size : ((icon_size + padding * 2) // 2)).to_i64
    if aliases
      @aliases = aliases.dup
    end
    self.item_ids = item_ids
    self
  end

  # Registers a key alias (e.g. `"happy" => "smile"`).
  def register_alias(from_key : String, to_key : String) : Void
    @aliases[from_key.strip.downcase] = to_key.strip.downcase
    @lookup_cache = nil
  end

  def aliases : Hash(String, String)
    @aliases
  end

  # Ordered array of raw SVG basenames (without `.svg` extension).
  def item_ids : Array(String)
    sync_caches_if_needed
    @item_ids_cache.not_nil!
  end

  def item_ids=(ids : Array(String)) : Array(String)
    @item_ids_cache = ids.dup
    @item_ids_csv = ids.join(",")
    @cached_ids_csv = @item_ids_csv
    derived_keys = ids.map { |id| SpritesheetAtlas.derive_key(id, @strip_prefix) }
    @item_keys_cache = derived_keys
    @item_keys_csv = derived_keys.join(",")
    @cached_keys_csv = @item_keys_csv
    @count = ids.size.to_i64
    cols = hframes
    @rows = (ids.size > 0 ? ((ids.size + cols - 1) // cols) : 1).to_i64
    @lookup_cache = nil
    ids
  end

  # Ordered array of canonical short keys corresponding to `item_ids`.
  def item_keys : Array(String)
    sync_caches_if_needed
    @item_keys_cache.not_nil!
  end

  def item_keys=(keys : Array(String)) : Array(String)
    @item_keys_cache = keys.dup
    @item_keys_csv = keys.join(",")
    @cached_keys_csv = @item_keys_csv
    @lookup_cache = nil
    keys
  end

  def ids : Array(String)
    item_ids
  end

  def keys : Array(String)
    item_keys
  end

  # Number of horizontal columns (`hframes` uniform in `pattern_replace.gdshader`).
  def hframes : Int32
    Math.max(@columns.to_i32, 1)
  end

  # Number of vertical rows (`vframes` uniform in `pattern_replace.gdshader`).
  def vframes : Int32
    Math.max(@rows.to_i32, 1)
  end

  # Padded viewBox size of a single cell (`icon_size + padding * 2`).
  def cell_size : Int32
    @icon_size.to_i32 + (@padding.to_i32 * 2)
  end

  # Rendered pixel width/height per cell on the final SVG spritesheet.
  def effective_cell_px_size : Int32
    @cell_px_size > 0 ? @cell_px_size.to_i32 : (cell_size // 2)
  end

  # Total number of items in the spritesheet.
  def size : Int32
    item_ids.size
  end

  # Looks up the 0-based sprite frame index for `key` (`String` or `Char`), raising `KeyError` if not found.
  def [](key : String | Char) : Int32
    self[key]? || raise KeyError.new("Unknown spritesheet key '#{key}' in #{atlas_name.empty? ? "SpritesheetAtlas" : atlas_name}")
  end

  # Looks up the 0-based sprite frame index for `key` (`Symbol`), raising `KeyError` if not found.
  def [](key : Symbol) : Int32
    self[key.to_s]
  end

  # Looks up the 0-based sprite frame index for `key` (`String` or `Char`), or returns `nil` if not found.
  def []?(key : String | Char) : Int32?
    map = lookup_table
    raw = key.to_s.strip.downcase
    return nil if raw.empty?
    if idx = map[raw]?
      return idx
    end
    hyph = raw.gsub('_', '-')
    if idx = map[hyph]?
      return idx
    end
    norm = normalize_key(raw)
    map[norm]?
  end

  # Looks up the 0-based sprite frame index for `key` (`Symbol`), or returns `nil` if not found.
  def []?(key : Symbol) : Int32?
    self[key.to_s]?
  end

  # Returns `true` if `key` exists in this spritesheet atlas.
  def has?(key : String | Char | Symbol) : Bool
    !self[key]?.nil?
  end

  # Returns the canonical short key at 0-based `index`.
  def key_at(index : Int) : String
    item_keys[index.to_i32]
  end

  def key_at?(index : Int) : String?
    item_keys[index.to_i32]?
  end

  # Returns the raw SVG basename ID at 0-based `index`.
  def id_at(index : Int) : String
    item_ids[index.to_i32]
  end

  def id_at?(index : Int) : String?
    item_ids[index.to_i32]?
  end

  # Returns full `ItemInfo` metadata for `key` (`String`, `Char`, or `Symbol`), raising `KeyError` if not found.
  def info(key : String | Char | Symbol) : ItemInfo
    info?(key) || raise KeyError.new("Unknown spritesheet key '#{key}' in #{atlas_name.empty? ? "SpritesheetAtlas" : atlas_name}")
  end

  # Returns full `ItemInfo` metadata for `key` (`String`, `Char`, or `Symbol`), or `nil` if not found.
  def info?(key : String | Char | Symbol) : ItemInfo?
    if idx = self[key]?
      info_at?(idx)
    else
      nil
    end
  end

  # Returns full `ItemInfo` metadata for the 0-based frame `index`, raising `IndexError` if out of bounds.
  def info_at(index : Int) : ItemInfo
    info_at?(index) || raise IndexError.new("Spritesheet frame index #{index} out of bounds (0...#{size})")
  end

  # Returns full `ItemInfo` metadata for the 0-based frame `index`, or `nil` if out of bounds.
  def info_at?(index : Int) : ItemInfo?
    idx = index.to_i32
    ids_list = item_ids
    return nil if idx < 0 || idx >= ids_list.size
    keys_list = item_keys
    id = ids_list[idx]
    k = idx < keys_list.size ? keys_list[idx] : SpritesheetAtlas.derive_key(id, @strip_prefix)
    cols = hframes
    rws = vframes
    col = idx % cols
    row = idx // cols
    c_size = cell_size.to_f32
    uv_w = 1.0_f32 / cols.to_f32
    uv_h = 1.0_f32 / rws.to_f32
    uv_rect = Rect2.new(col.to_f32 * uv_w, row.to_f32 * uv_h, uv_w, uv_h)
    cell_rect = Rect2.new(col.to_f32 * c_size, row.to_f32 * c_size, c_size, c_size)

    ItemInfo.new(
      index: idx,
      id: id,
      key: k,
      column: col,
      row: row,
      hframes: cols,
      vframes: rws,
      uv_rect: uv_rect,
      cell_rect: cell_rect
    )
  end

  # Returns `ItemInfo` for all items in the atlas in frame order.
  def entries : Array(ItemInfo)
    (0...size).map { |i| info_at(i) }
  end

  # Preloads and returns the Godot `Texture2D` for `texture_path` when running inside Godot.
  def texture : Texture2D?
    return nil if @texture_path.empty?
    Godot.preload?(@texture_path, Texture2D)
  rescue
    nil
  end

  # Applies this atlas's `base_texture`, `hframes`, `vframes`, and the resolved `frame` for `key`
  # onto a `ShaderMaterial` (such as one using `pattern_replace.gdshader`).
  def apply_to(material : ShaderMaterial, key : String | Char | Symbol) : Int32
    frame_idx = self[key]
    if !material.pointer.null?
      if tex = texture
        material.call("set_shader_parameter", "base_texture", tex) if !tex.pointer.null?
      end
      material.call("set_shader_parameter", "hframes", hframes.to_i64)
      material.call("set_shader_parameter", "vframes", vframes.to_i64)
      material.call("set_shader_parameter", "frame", frame_idx.to_i64)
    end
    frame_idx
  end

  private def sync_caches_if_needed : Void
    if @item_ids_cache.nil? || @cached_ids_csv != @item_ids_csv
      @cached_ids_csv = @item_ids_csv
      @item_ids_cache = @item_ids_csv.empty? ? ([] of String) : @item_ids_csv.split(',', remove_empty: true)
      @count = @item_ids_cache.not_nil!.size.to_i64
      @lookup_cache = nil
    end
    if @item_keys_cache.nil? || @cached_keys_csv != @item_keys_csv
      @cached_keys_csv = @item_keys_csv
      if @item_keys_csv.empty?
        @item_keys_cache = @item_ids_cache.not_nil!.map { |id| SpritesheetAtlas.derive_key(id, @strip_prefix) }
      else
        @item_keys_cache = @item_keys_csv.split(',', remove_empty: true)
      end
      @lookup_cache = nil
    end
  end

  private def lookup_table : Hash(String, Int32)
    sync_caches_if_needed
    if existing = @lookup_cache
      return existing
    end

    ids_list = @item_ids_cache.not_nil!
    keys_list = @item_keys_cache.not_nil!
    table = Hash(String, Int32).new(initial_capacity: ids_list.size * 4)

    ids_list.each_with_index do |raw_id, idx|
      id_down = raw_id.downcase
      short_k = (idx < keys_list.size ? keys_list[idx] : SpritesheetAtlas.derive_key(raw_id, @strip_prefix)).downcase

      table[id_down] = idx
      table[id_down.gsub('-', '_')] = idx
      table[short_k] = idx
      table[short_k.gsub('-', '_')] = idx
    end

    @aliases.each do |from_k, to_k|
      if target_idx = table[to_k]? || table[to_k.gsub('_', '-')]?
        table[from_k] = target_idx
        table[from_k.gsub('-', '_')] = target_idx
        table[from_k.gsub('_', '-')] = target_idx
      end
    end

    @lookup_cache = table
    table
  end
end
