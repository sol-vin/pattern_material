require "json"
require "lapis"
require "./svg_spritesheet_builder"

include Godot

# Categorizes and imports FontAwesome Pro 7.1.0 `duotone-regular` SVGs into
# mutually exclusive `textures/fontawesome/<category>/` directories, normalizing
# secondary duotone layers (`opacity=".4"`) to solid white (`#ffffff`) for use
# with `addons/pattern_material/shaders/pattern_replace.gdshader`.
module FontAwesomeCategories
  FA_DEFAULT_ROOT = "C:/Users/Ian/Documents/Downloads/fontawesome-pro-7.1.0-web"
  TARGET_ROOT     = "textures/fontawesome"
  MANIFEST_PATH   = "textures/fontawesome/categories_manifest.json"

  CATEGORIES = [
    "faces",
    "letter_glyphs",
    "animal",
    "arrows",
    "buildings",
    "charts_math",
    "clothing",
    "commerce",
    "communication",
    "devices",
    "editing",
    "files",
    "food",
    "gaming",
    "hands",
    "household",
    "maps",
    "media",
    "medical",
    "nature",
    "people",
    "science",
    "security",
    "shapes",
    "sports",
    "time",
    "tools",
    "vehicles",
    "weather",
  ]

  # Stage 1: Primary visual prefix rules (evaluated in order before FA category fallback).
  PREFIX_RULES = [
    {"arrows", [
      "arrow", "arrows", "angle-down", "angle-left", "angle-right", "angle-up",
      "angles", "chevron", "chevrons", "caret", "carets", "turn", "rotate",
      "repeat", "retweet", "shuffle", "sort", "left", "right", "up", "down",
      "merge", "split", "expand", "compress", "maximize", "minimize", "forward",
      "backward", "reply", "share", "spinner", "circle-notch",
    ]},
    {"hands", [
      "hand", "hands", "thumbs-up", "thumbs-down", "handshake", "fist-raised", "face",
    ]},
    {"people", [
      "user", "users", "person", "people", "child", "children", "baby", "boy",
      "girl", "man", "woman", "male", "female", "family", "id-card", "id-badge",
      "address-card", "address-book", "portrait", "head-side", "mars", "venus",
      "transgender", "neuter", "genderless", "non-binary",
    ]},
    {"animal", [
      "alicorn", "ant", "badger", "bat", "bee", "bird", "bugs", "butterfly",
      "cat", "cow", "crab", "crow", "deer", "dinosaur", "dog", "dolphin",
      "dove", "dragon", "duck", "elephant", "feather", "fish", "frog", "hippo",
      "horse", "horseshoe", "hydra", "kiwi-bird", "lobster", "locust", "monkey",
      "mosquito", "mouse-field", "narwhal", "octopus", "otter", "paw", "pegasus",
      "pig", "rabbit", "raccoon", "ram", "sheep", "shrimp", "skull-cow", "snake",
      "spider", "squid", "squirrel", "t-rex", "teddy-bear", "turtle", "unicorn",
      "whale", "worm",
    ]},
    {"tools", [
      "hammer", "wrench", "screwdriver", "saw", "shovel", "trowel", "pickaxe",
      "axe", "toolbox", "ruler", "compass-drafting", "paint-roller", "paintbrush",
      "brush", "scissors", "scalpel", "flashlight", "ladder", "hose", "bucket",
      "broom", "mop", "vacuum", "sponge", "sprinkler", "wheelbarrow", "gear",
      "gears", "anvil", "chainsaw", "drill", "pliers", "clamp", "vise", "tape",
      "stapler", "paperclip", "needle", "fishing-rod", "pocket-knife", "knife",
      "angle", "angle-90", "helmet-safety", "bore-hole", "grate", "mound", "reel",
      "sheet-plastic", "magnifying-glass",
    ]},
    {"gaming", [
      "sword", "swords", "dagger", "bow-arrow", "mace", "staff", "wand",
      "scroll-old", "dungeon", "dice", "chess", "card-club", "card-diamond",
      "card-heart", "card-spade", "cards", "club", "spade", "gamepad", "joystick",
      "alien", "ufo", "robot", "raygun", "transporter", "hat-wizard", "hat-witch",
      "book-spells", "book-skull", "book-sparkles", "crystal-ball",
      "flask-round-potion", "flask-potion", "treasure-chest", "helmet-battle",
      "scythe", "sickle", "bomb", "explosion", "gun", "crosshairs", "bullseye",
      "ghost", "skull", "jack-o-lantern", "cauldron", "coffin", "tombstone",
      "hockey-mask", "puzzle-piece", "block-question",
    ]},
    {"science", [
      "atom", "flask", "vial", "vials", "microscope", "telescope", "satellite",
      "planet", "comet", "meteor", "galaxy", "eclipse", "orbit", "radar", "dna",
      "magnet", "radiation", "biohazard", "solar-panel", "solar-system",
    ]},
    {"medical", [
      "heart-pulse", "heartbeat", "stethoscope", "syringe", "pills", "capsules",
      "tablets", "prescription", "bottle-medical", "briefcase-medical",
      "kit-medical", "suitcase-medical", "notes-medical", "bed-pulse", "stretcher",
      "wheelchair", "crutch", "crutches", "cane", "tooth", "teeth", "bone",
      "bones", "brain", "lungs", "kidneys", "liver", "stomach", "intestines",
      "eye", "eyes", "ear", "nose", "lips", "mouth", "tongue", "virus", "viruses",
      "bacteria", "bacterium", "disease", "bandage", "x-ray", "braille",
      "universal-access",
    ]},
    {"weather", [
      "cloud", "sun", "moon", "wind", "temperature", "thermometer", "snowflake",
      "snow", "rain", "raindrops", "umbrella", "tornado", "hurricane", "rainbow",
      "smog", "fog", "icicles", "droplet", "bolt",
    ]},
    {"nature", [
      "tree", "trees", "leaf", "flower", "seedling", "plant", "cactus", "clover",
      "mushroom", "acorn", "chestnut", "wheat", "grass", "mountain", "mountains",
      "volcano", "water", "wave", "fire", "campfire", "campground", "forest",
      "island", "bug", "cannabis", "bench-tree", "binoculars",
    ]},
    {"food", [
      "utensils", "fork", "spoon", "plate", "bowl", "cup", "mug", "glass", "wine",
      "beer", "whiskey", "martini", "champagne", "cocktail", "burger", "pizza",
      "taco", "hotdog", "sandwich", "bread", "croissant", "cake", "cookie",
      "candy", "ice-cream", "egg", "cheese", "meat", "drumstick", "bacon",
      "steak", "sausage", "soup", "salad", "sushi", "ramen", "pot-food",
      "pan-food", "oven", "microwave", "blender", "toaster", "refrigerator",
      "apple", "avocado", "banana", "berry", "blueberries", "broccoli", "carrot",
      "cherries", "chili", "citrus", "coconut", "corn", "cucumber", "eggplant",
      "fig", "garlic", "grapes", "kiwi-fruit", "lemon", "lettuce", "mango",
      "melon", "olive", "onion", "orange", "pea", "peach", "peanut", "pear",
      "pepper", "pineapple", "plum", "pomegranate", "potato", "pumpkin", "radish",
      "strawberry", "tomato", "watermelon", "wheat-awn", "coffee", "tea",
      "bottle-water", "bottle-droplet", "can-food", "jar", "aeropress",
    ]},
    {"vehicles", [
      "car", "cars", "truck", "van", "bus", "taxi", "tractor", "trailer",
      "bulldozer", "excavator", "forklift", "motorcycle", "moped", "scooter",
      "bicycle", "train", "tram", "subway", "plane", "jet", "helicopter",
      "rocket", "shuttle", "ship", "boat", "sailboat", "ferry", "yacht", "canoe",
      "anchor", "rudder", "wheel", "tire", "gas-pump", "charging-station",
      "oil-can", "engine", "gauge", "tachometer", "traffic", "road", "highway",
      "parachute", "sleigh", "cable-car", "cart-flatbed", "dolly", "baby-carriage",
    ]},
    {"buildings", [
      "house", "home", "building", "buildings", "apartment", "cabin", "castle",
      "church", "mosque", "synagogue", "temple", "torii", "vihara", "kaaba",
      "gopuram", "place-of-worship", "landmark", "monument", "archway", "tower",
      "lighthouse", "windmill", "barn", "silo", "warehouse", "factory",
      "industry", "shop", "store", "school", "university", "hotel", "hospital",
      "clinic", "tent", "igloo", "city", "tree-city", "mountain-city", "bridge",
      "fence", "gate", "door", "window", "stairs", "elevator", "escalator",
      "restroom",
    ]},
    {"sports", [
      "baseball", "basketball", "football", "futbol", "volleyball", "tennis",
      "golf", "hockey", "cricket", "rugby", "bowling", "curling", "lacrosse",
      "badminton", "racquet", "table-tennis", "dumbbell", "weight", "medal",
      "trophy", "award", "podium", "whistle", "ski", "skiing", "snowboarding",
      "sledding", "swimming", "swimmer", "running", "biking", "ball-pile",
      "goal-net", "boxing-glove", "skates", "ice-skate", "roller-skate",
    ]},
    {"clothing", [
      "shirt", "tshirt", "vest", "jacket", "coat", "hoodie", "sweater", "dress",
      "skirt", "pants", "jeans", "shorts", "underwear", "briefs", "bra", "socks",
      "stocking", "shoe", "shoes", "boot", "boots", "sandal", "slipper", "hat",
      "cap", "beanie", "beret", "helmet", "glasses", "sunglasses", "goggles",
      "mask", "scarf", "mitten", "gloves", "tie", "bowtie", "belt", "ring", "gem",
      "necklace", "earrings", "clothes-hanger", "washing-machine", "iron",
      "dryer", "crown", "ball-yarn", "reel",
    ]},
    {"files", [
      "file", "files", "folder", "folders", "book", "books", "bookmark",
      "notebook", "journal", "newspaper", "scroll", "page", "note", "notes",
      "clipboard", "paste", "copy", "clone", "print", "pen", "pencil", "marker",
      "highlighter", "crayon", "eraser", "signature", "stamp", "graduation-cap",
      "chalkboard", "diploma", "box-archive",
    ]},
    {"communication", [
      "comment", "comments", "message", "messages", "envelope", "envelopes",
      "inbox", "mailbox", "paper-plane", "phone", "tty", "voicemail",
      "walkie-talkie", "at", "hashtag", "bullhorn", "megaphone", "bell", "bells",
      "rss", "quote", "satellite-dish",
    ]},
    {"media", [
      "music", "guitar", "piano", "drum", "trumpet", "violin", "saxophone",
      "flute", "banjo", "mandolin", "clarinet", "harp", "accordion", "kazoo",
      "turntable", "record-vinyl", "compact-disc", "cassette", "album", "radio",
      "boombox", "speaker", "headphones", "headset", "earbuds", "microphone",
      "podcast", "waveform", "volume", "equalizer", "play", "pause", "stop",
      "eject", "film", "video", "camcorder", "camera", "image", "images", "photo",
      "panorama", "clapperboard", "projector", "tv-retro", "airplay",
      "screencast", "closed-captioning", "subtitles", "audio-description",
      "aperture", "360-degrees",
    ]},
    {"devices", [
      "computer", "desktop", "laptop", "tablet", "mobile", "display", "tv",
      "monitor", "keyboard", "mouse", "printer", "fax", "scanner", "server",
      "database", "hard-drive", "floppy-disk", "sd-card", "sim-card", "memory",
      "microchip", "cpu", "usb", "ethernet", "wifi", "bluetooth", "signal",
      "tower-broadcast", "tower-cell", "router", "network-wired", "code",
      "terminal", "brackets", "binary", "sitemap", "download", "upload", "qrcode",
      "barcode", "plug", "battery",
    ]},
    {"commerce", [
      "dollar", "euro", "pound", "sterling", "yen", "won", "ruble", "rupee",
      "rupiah", "baht", "lira", "franc", "peso", "real", "shekel", "krone",
      "krona", "zloty", "forint", "koruna", "hryvnia", "tenge", "tugrik",
      "manat", "lari", "cedi", "naira", "guarani", "colon", "cruzeiro", "dong",
      "kip", "mill", "peseta", "florin", "austral", "bitcoin", "litecoin",
      "ethereum", "coins", "coin", "money", "cash", "wallet", "credit-card",
      "receipt", "invoice", "cart", "bag-shopping", "bags-shopping",
      "basket-shopping", "tag", "tags", "scale", "vault", "piggy-bank", "sack",
      "briefcase", "trademark", "registered", "copyright", "scale-balanced",
      "gavel", "presentation", "timeline",
    ]},
    {"charts_math", [
      "chart", "diagram", "graph", "analytics", "abacus", "calculator",
      "infinity", "function", "integral", "sigma", "pi", "square-root", "plus",
      "minus", "divide", "equals", "not-equal", "less-than", "greater-than",
      "percent", "tally", "0", "00", "1", "2", "3", "4", "5", "6", "7", "8", "9",
      "bar-progress", "bars-progress",
    ]},
    {"time", [
      "clock", "watch", "alarm", "timer", "stopwatch", "hourglass", "calendar",
      "calendars", "snooze", "gift", "gifts", "cake-candles", "party", "balloon",
      "balloons", "holly", "mistletoe", "snowman", "wreath", "candy-cane",
      "ornament", "menorah", "dreidel",
    ]},
    {"maps", [
      "location", "map", "compass", "route", "signs-post", "sign-post",
      "street-view", "earth", "globe", "flag", "flags", "passport", "ticket",
      "thumbtack", "umbrella-beach",
    ]},
    {"security", [
      "shield", "lock", "unlock", "key", "keys", "padlock", "fingerprint",
      "badge", "siren", "light-emergency", "triangle-exclamation",
      "circle-exclamation", "octagon-exclamation", "diamond-exclamation",
      "seal-exclamation", "exclamation", "question", "info", "ban",
      "do-not-enter", "skull-crossbones", "fire-extinguisher", "sensor", "cross",
      "ankh", "star-of-david", "star-and-crescent", "om", "dharmachakra",
      "yin-yang", "peace", "bahai", "khanda", "ballot", "check-to-slot",
      "democrat", "republican", "section",
    ]},
    {"household", [
      "couch", "sofa", "chair", "loveseat", "bed", "mattress", "blanket", "rug",
      "curtains", "blinds", "lamp", "light", "lightbulb", "chandelier", "sconce",
      "candle", "fan", "air-conditioner", "heater", "fireplace", "radiator",
      "outlet", "suitcase", "luggage", "bag", "backpack", "trash", "dumpster",
      "recycle", "bin", "basket", "box", "boxes", "crate", "jug", "bottle", "can",
      "toilet", "bath", "shower", "sink", "faucet", "toilet-paper", "soap",
      "toothbrush", "toothpaste", "pump-soap", "spray-can", "air-freshener",
    ]},
    {"editing", [
      "align", "bold", "italic", "underline", "strikethrough", "subscript",
      "superscript", "text", "font", "heading", "paragraph", "indent", "outdent",
      "list", "table", "columns", "border", "crop", "cut", "lasso", "wand-magic",
      "palette", "swatchbook", "fill", "eye-dropper", "layer-group", "object",
      "vector", "bezier-curve", "pen-nib", "grid", "bars", "ellipsis", "filter",
      "sliders", "toggle", "check", "xmark",
    ]},
    {"shapes", [
      "heart", "star", "diamond", "triangle", "hexagon", "octagon", "pentagon",
      "rectangle", "rhombus", "cube", "cubes", "shapes", "burst", "sparkle",
      "sparkles", "asterisk", "certificate", "seal",
    ]},
  ]

  # Stage 2: Priority-ordered FontAwesome `categories.yml` fallback.
  CAT_FALLBACK = [
    {"arrows", ["arrows", "spinners"]},
    {"animal", ["animals"]},
    {"tools", ["construction"]},
    {"gaming", ["gaming", "science-fiction", "halloween"]},
    {"science", ["science", "astronomy"]},
    {"medical", ["medical-health", "accessibility"]},
    {"weather", ["weather"]},
    {"nature", ["nature", "camping"]},
    {"food", ["fruits-vegetables", "food-beverage"]},
    {"sports", ["sports-fitness"]},
    {"vehicles", ["automotive", "transportation", "maritime"]},
    {"buildings", ["buildings"]},
    {"clothing", ["clothing-fashion"]},
    {"hands", ["hands", "emoji"]},
    {"people", ["users-people", "gender", "childhood"]},
    {"files", ["files", "writing", "education"]},
    {"communication", ["communication", "social"]},
    {"media", ["music-audio", "film-video", "photos-images", "media-playback"]},
    {"devices", ["devices-hardware", "connectivity", "coding"]},
    {"commerce", ["money", "shopping", "business", "marketing", "charity"]},
    {"charts_math", ["charts-diagrams", "mathematics", "numbers", "alphabet", "punctuation-symbols"]},
    {"time", ["time", "holidays"]},
    {"editing", ["editing", "design", "text-formatting", "toggle"]},
    {"household", ["household", "energy", "moving", "logistics"]},
    {"maps", ["maps", "travel-hotel"]},
    {"security", ["security", "alert", "religion", "political", "disaster", "humanitarian"]},
    {"shapes", ["shapes"]},
  ]

  struct ImportSummary
    getter total_canonical : Int32
    getter total_aliases : Int32
    getter imported_new : Int32
    getter category_counts : Hash(String, Int32)

    def initialize(
      @total_canonical : Int32,
      @total_aliases : Int32,
      @imported_new : Int32,
      @category_counts : Hash(String, Int32)
    )
    end
  end

  @@icon_to_category : Hash(String, String)? = nil
  @@category_to_icons : Hash(String, Array(String))? = nil
  @@alias_to_canonical : Hash(String, String)? = nil

  def self.has_prefix?(icon : String, prefixes : Array(String)) : Bool
    prefixes.each do |p|
      return true if icon == p || icon.starts_with?("#{p}-")
    end
    false
  end

  # Classifies a single canonical icon ID into one of the 29 mutually exclusive categories.
  def self.classify_icon(
    icon : String,
    faces_set : Set(String),
    glyphs_set : Set(String),
    fa_cats : Hash(String, Set(String))
  ) : String
    return "faces" if faces_set.includes?(icon)
    return "letter_glyphs" if glyphs_set.includes?(icon)
    return "charts_math" if icon.size == 1

    PREFIX_RULES.each do |cat_name, prefixes|
      return cat_name if has_prefix?(icon, prefixes)
    end

    CAT_FALLBACK.each do |cat_name, fa_cat_names|
      fa_cat_names.each do |fc|
        if set = fa_cats[fc]?
          return cat_name if set.includes?(icon)
        end
      end
    end

    "shapes"
  end

  # Parses FontAwesome `metadata/categories.yml` into `Hash(category_name, Set(icon_id))`.
  def self.parse_categories_yml(yml_path : String, valid_icons : Set(String)? = nil) : Hash(String, Set(String))
    result = Hash(String, Set(String)).new
    return result unless File.exists?(yml_path)

    cur_cat = ""
    in_icons = false

    File.each_line(yml_path) do |line|
      if !line.starts_with?(" ") && line.strip.ends_with?(":")
        cur_cat = line.strip[0...-1]
        result[cur_cat] = Set(String).new
        in_icons = false
      elsif line.starts_with?("  icons:")
        in_icons = True_bool
      elsif line.starts_with?("  label:")
        in_icons = false
      elsif in_icons && line.starts_with?("    - ")
        raw_icon = line.strip[2..].strip.strip("'\"")
        if valid_icons.nil? || valid_icons.includes?(raw_icon)
          result[cur_cat] << raw_icon unless cur_cat.empty?
        end
      end
    end

    result
  end

  private True_bool = true

  # Imports and categorizes all canonical icons from `fa_root/svgs-full/duotone-regular`
  # into `target_root/<category>/`, preserving `faces` and `letter_glyphs`.
  def self.import_all(
    fa_root : String = FA_DEFAULT_ROOT,
    target_root : String = TARGET_ROOT,
    manifest_path : String = MANIFEST_PATH
  ) : ImportSummary
    svg_dir = File.join(fa_root, "svgs-full", "duotone-regular")
    icons_json_path = File.join(fa_root, "metadata", "icons.json")
    cats_yml_path = File.join(fa_root, "metadata", "categories.yml")

    unless Dir.exists?(svg_dir)
      raise "FontAwesome duotone-regular directory not found: #{svg_dir}"
    end

    all_svgs = Set(String).new
    Dir.children(svg_dir).each do |fname|
      if fname.downcase.ends_with?(".svg")
        all_svgs << File.basename(fname, ".svg")
      end
    end

    canonicals = Set(String).new
    alias_map = Hash(String, String).new

    if File.exists?(icons_json_path)
      json_any = JSON.parse(File.read(icons_json_path))
      if hash = json_any.as_h?
        hash.each do |canonical_id, data|
          next unless all_svgs.includes?(canonical_id)
          canonicals << canonical_id
          if aliases_obj = data["aliases"]?
            if names_arr = aliases_obj["names"]?.try(&.as_a?)
              names_arr.each do |a_val|
                if a_str = a_val.as_s?
                  alias_map[a_str] = canonical_id if all_svgs.includes?(a_str) && a_str != canonical_id
                end
              end
            end
            if uni_obj = aliases_obj["unicodes"]?.try(&.as_h?)
              uni_obj.each_value do |a_val|
                if a_str = a_val.as_s?
                  alias_map[a_str] = canonical_id if all_svgs.includes?(a_str) && a_str != canonical_id
                end
              end
            end
          end
        end
      end
    else
      canonicals = all_svgs.dup
    end

    fa_cats = parse_categories_yml(cats_yml_path, canonicals)

    faces_dir = File.join(target_root, "faces")
    glyphs_dir = File.join(target_root, "letter_glyphs")

    faces_set = Set(String).new
    if Dir.exists?(faces_dir)
      Dir.children(faces_dir).each do |f|
        faces_set << File.basename(f, ".svg") if f.downcase.ends_with?(".svg")
      end
    else
      Faces::DEFAULT_IDS.each { |id| faces_set << id }
    end

    glyphs_set = Set(String).new
    if Dir.exists?(glyphs_dir)
      Dir.children(glyphs_dir).each do |f|
        glyphs_set << File.basename(f, ".svg") if f.downcase.ends_with?(".svg")
      end
    else
      Glyphs::DEFAULT_IDS.each { |id| glyphs_set << id }
    end

    buckets = Hash(String, Array(String)).new
    CATEGORIES.each { |c| buckets[c] = [] of String }

    canonicals.to_a.sort!.each do |icon_id|
      cat = classify_icon(icon_id, faces_set, glyphs_set, fa_cats)
      buckets[cat] << icon_id
    end

    # Include non-FontAwesome custom icons already in faces/ or letter_glyphs/ in manifest tracking
    faces_set.each do |f_id|
      buckets["faces"] << f_id unless buckets["faces"].includes?(f_id)
    end
    buckets["faces"].sort!

    glyphs_set.each do |g_id|
      buckets["letter_glyphs"] << g_id unless buckets["letter_glyphs"].includes?(g_id)
    end
    buckets["letter_glyphs"].sort!

    imported_new = 0

    CATEGORIES.each do |cat|
      cat_dir = File.join(target_root, cat)
      Dir.mkdir_p(cat_dir) unless Dir.exists?(cat_dir)

      # Preserve existing `faces` and `letter_glyphs` directories untouched
      next if cat == "faces" || cat == "letter_glyphs"

      expected_files = Set(String).new
      buckets[cat].each do |icon_id|
        fname = "#{icon_id}.svg"
        expected_files << fname
        src_path = File.join(svg_dir, fname)
        dst_path = File.join(cat_dir, fname)
        next unless File.exists?(src_path)

        raw_svg = File.read(src_path)
        normalized_svg = SvgSpritesheetBuilder.normalize_svg(raw_svg)

        if !File.exists?(dst_path) || File.read(dst_path) != normalized_svg
          File.write(dst_path, normalized_svg)
        end
        imported_new += 1
      end

      # Remove any stale `.svg` files in this category directory that do not belong to `buckets[cat]`
      Dir.children(cat_dir).each do |existing|
        if existing.downcase.ends_with?(".svg") && !expected_files.includes?(existing)
          File.delete(File.join(cat_dir, existing)) rescue nil
        end
      end
    end

    counts = Hash(String, Int32).new
    CATEGORIES.each { |c| counts[c] = buckets[c].size }

    # Write manifest JSON
    manifest_dir = File.dirname(manifest_path)
    Dir.mkdir_p(manifest_dir) unless Dir.exists?(manifest_dir)

    manifest_json = JSON.build(indent: "  ") do |json|
      json.object do
        json.field "version", "7.1.0"
        json.field "style", "duotone-regular"
        json.field "total_canonical", canonicals.size
        json.field "total_aliases", alias_map.size
        json.field "category_count", CATEGORIES.size
        json.field "category_counts" do
          json.object do
            CATEGORIES.each do |c|
              json.field c, counts[c]
            end
          end
        end
        json.field "categories" do
          json.object do
            CATEGORIES.each do |c|
              json.field c do
                json.array do
                  buckets[c].each { |id| json.string(id) }
                end
              end
            end
          end
        end
        json.field "aliases" do
          json.object do
            alias_map.keys.sort!.each do |alias_id|
              json.field alias_id, alias_map[alias_id]
            end
          end
        end
      end
    end

    File.write(manifest_path, manifest_json + "\n")
    reload_cache_from_manifest(manifest_path)

    ImportSummary.new(
      total_canonical: canonicals.size,
      total_aliases: alias_map.size,
      imported_new: imported_new,
      category_counts: counts
    )
  end

  # Loads category and alias lookup tables from `textures/fontawesome/categories_manifest.json` (or scans directories).
  def self.reload_cache_from_manifest(manifest_path : String = MANIFEST_PATH) : Void
    icon_cat = Hash(String, String).new
    cat_icons = Hash(String, Array(String)).new
    alias_can = Hash(String, String).new

    resolved_manifest = SvgSpritesheetBuilder.resolve_filesystem_path(manifest_path)
    if File.exists?(resolved_manifest)
      data = JSON.parse(File.read(resolved_manifest))
      if cats_obj = data["categories"]?.try(&.as_h?)
        cats_obj.each do |cat, arr_val|
          list = [] of String
          if arr = arr_val.as_a?
            arr.each do |item|
              if id = item.as_s?
                list << id
                icon_cat[id] = cat
              end
            end
          end
          cat_icons[cat] = list
        end
      end
      if aliases_obj = data["aliases"]?.try(&.as_h?)
        aliases_obj.each do |al, can_val|
          if can = can_val.as_s?
            alias_can[al] = can
          end
        end
      end
    else
      CATEGORIES.each do |cat|
        dir = SvgSpritesheetBuilder.resolve_filesystem_path("#{TARGET_ROOT}/#{cat}")
        list = [] of String
        if Dir.exists?(dir)
          Dir.children(dir).each do |f|
            if f.downcase.ends_with?(".svg")
              id = File.basename(f, ".svg")
              list << id
              icon_cat[id] = cat
            end
          end
          list.sort!
        end
        cat_icons[cat] = list
      end
    end

    @@icon_to_category = icon_cat
    @@category_to_icons = cat_icons
    @@alias_to_canonical = alias_can
  end

  private def self.ensure_loaded : Void
    reload_cache_from_manifest if @@icon_to_category.nil?
  end

  def self.categories : Array(String)
    CATEGORIES
  end

  def self.icons_in(category : String | Symbol) : Array(String)
    ensure_loaded
    key = category.to_s.strip.downcase.gsub('-', '_')
    @@category_to_icons.not_nil![key]? || ([] of String)
  end

  # Resolves an icon name (or legacy FontAwesome alias) to its canonical icon ID.
  def self.canonical_id(icon : String | Symbol) : String
    ensure_loaded
    norm = icon.to_s.strip.downcase.sub(/\.svg$/, "").gsub('_', '-')
    @@alias_to_canonical.not_nil![norm]? || norm
  end

  # Returns the category name (`"animal"`, `"tools"`, etc.) for `icon` (accepts canonical IDs or aliases), or `nil`.
  def self.category_for?(icon : String | Symbol) : String?
    ensure_loaded
    can = canonical_id(icon)
    @@icon_to_category.not_nil![can]?
  end

  def self.category_for(icon : String | Symbol) : String
    category_for?(icon) || raise KeyError.new("Unknown FontAwesome icon '#{icon}'")
  end

  # Returns the `res://textures/fontawesome/<category>/<canonical_id>.svg` path for `icon`, or `nil`.
  def self.path?(icon : String | Symbol) : String?
    ensure_loaded
    can = canonical_id(icon)
    if cat = @@icon_to_category.not_nil![can]?
      "res://#{TARGET_ROOT}/#{cat}/#{can}.svg"
    else
      nil
    end
  end

  def self.path(icon : String | Symbol) : String
    path?(icon) || raise KeyError.new("Unknown FontAwesome icon '#{icon}'")
  end

  def self.[](icon : String | Symbol) : String
    path(icon)
  end

  def self.[]?(icon : String | Symbol) : String?
    path?(icon)
  end
end
