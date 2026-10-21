require "./pattern_generator"

include Godot

# Procedural Polka Dot & Ring grid pattern generator.
@[Tool]
resource PolkaDotPattern < PatternGenerator do
  @[Export(range: 1.0..100.0, step: 0.5)]
  property dot_radius : Float64 = 18.0

  @[Export(range: 1..16, step: 1)]
  property columns : Int64 = 2_i64

  @[Export(range: 1..16, step: 1)]
  property rows : Int64 = 2_i64

  @[Export]
  property stagger : Bool = true

  @[Export(range: 0.0..50.0, step: 0.5)]
  property ring_thickness : Float64 = 0.0

  def dot_radius=(val : Float64)
    return if @dot_radius == val
    @dot_radius = val
    refresh_texture!
  end

  def columns=(val : Int64)
    return if @columns == val
    @columns = val
    refresh_texture!
  end

  def rows=(val : Int64)
    return if @rows == val
    @rows = val
    refresh_texture!
  end

  def stagger=(val : Bool)
    return if @stagger == val
    @stagger = val
    refresh_texture!
  end

  def ring_thickness=(val : Float64)
    return if @ring_thickness == val
    @ring_thickness = val
    refresh_texture!
  end

  def build_svg_body(io : IO, size : Float64, fg : String, bg : String) : Void
    cols = Math.max(@columns.to_i32, 1)
    rws = Math.max(@rows.to_i32, 1)
    cell_w = size / cols
    cell_h = size / rws
    r = Math.max(@dot_radius, 0.5)
    ring_w = @ring_thickness

    (0...rws).each do |row|
      offset_x = (@stagger && row.odd?) ? (cell_w * 0.5) : 0.0
      cy = (row + 0.5) * cell_h
      (0...cols).each do |col|
        cx = (col + 0.5) * cell_w + offset_x
        emit_dot(io, cx, cy, r, ring_w, fg)
        if cx + r > size
          emit_dot(io, cx - size, cy, r, ring_w, fg)
        elsif cx - r < 0.0
          emit_dot(io, cx + size, cy, r, ring_w, fg)
        end
      end
    end
  end

  private def emit_dot(io : IO, cx : Float64, cy : Float64, r : Float64, ring_w : Float64, fg : String) : Void
    if ring_w > 0.0
      io << %(  <circle cx="#{fmt(cx)}" cy="#{fmt(cy)}" r="#{fmt(r)}" fill="none" stroke="#{fg}" stroke-width="#{fmt(ring_w)}"/>\n)
    else
      io << %(  <circle cx="#{fmt(cx)}" cy="#{fmt(cy)}" r="#{fmt(r)}" fill="#{fg}"/>\n)
    end
  end
end

# Procedural Stripe, Diagonal Band, and Crosshatch/Plaid pattern generator.
@[Tool]
resource StripePattern < PatternGenerator do
  @[Export(range: 1..32, step: 1)]
  property stripe_count : Int64 = 4_i64

  @[Export(range: 0.05..0.95, step: 0.01)]
  property duty_cycle : Float64 = 0.5

  @[Export(range: -180.0..180.0, step: 1.0)]
  property angle_degrees : Float64 = 0.0

  @[Export]
  property crosshatch : Bool = false

  def stripe_count=(val : Int64)
    return if @stripe_count == val
    @stripe_count = val
    refresh_texture!
  end

  def duty_cycle=(val : Float64)
    return if @duty_cycle == val
    @duty_cycle = val
    refresh_texture!
  end

  def angle_degrees=(val : Float64)
    return if @angle_degrees == val
    @angle_degrees = val
    refresh_texture!
  end

  def crosshatch=(val : Bool)
    return if @crosshatch == val
    @crosshatch = val
    refresh_texture!
  end

  def build_svg_body(io : IO, size : Float64, fg : String, bg : String) : Void
    count = Math.max(@stripe_count.to_i32, 1)
    duty = @duty_cycle.clamp(0.05, 0.95)
    period = size / count
    bar_w = period * duty
    cx = size * 0.5
    cy = size * 0.5

    if @angle_degrees.abs > 1e-4
      io << %(  <g transform="rotate(#{fmt(@angle_degrees)},#{fmt(cx)},#{fmt(cy)})">\n)
      emit_stripes(io, size, count, period, bar_w, fg, overscan: true)
      io << %(  </g>\n)
    else
      emit_stripes(io, size, count, period, bar_w, fg, overscan: false)
    end

    if @crosshatch
      perp_angle = @angle_degrees + 90.0
      io << %(  <g transform="rotate(#{fmt(perp_angle)},#{fmt(cx)},#{fmt(cy)})">\n)
      emit_stripes(io, size, count, period, bar_w, fg, overscan: true)
      io << %(  </g>\n)
    end
  end

  private def emit_stripes(io : IO, size : Float64, count : Int32, period : Float64, bar_w : Float64, fg : String, overscan : Bool) : Void
    if overscan
      extra = count
      ((-extra)...(count + extra)).each do |i|
        x = i * period
        io << %(    <rect x="#{fmt(x)}" y="#{fmt(-size)}" width="#{fmt(bar_w)}" height="#{fmt(size * 3.0)}" fill="#{fg}"/>\n)
      end
    else
      (0...count).each do |i|
        x = i * period
        io << %(  <rect x="#{fmt(x)}" y="0" width="#{fmt(bar_w)}" height="#{fmt(size)}" fill="#{fg}"/>\n)
      end
    end
  end
end

# Procedural Checkerboard and Rounded Tile grid generator.
@[Tool]
resource CheckerPattern < PatternGenerator do
  @[Export(range: 1..32, step: 1)]
  property columns : Int64 = 2_i64

  @[Export(range: 1..32, step: 1)]
  property rows : Int64 = 2_i64

  @[Export(range: 0.0..20.0, step: 0.5)]
  property cell_inset : Float64 = 0.0

  @[Export(range: 0.0..25.0, step: 0.5)]
  property corner_radius : Float64 = 0.0

  def columns=(val : Int64)
    return if @columns == val
    @columns = val
    refresh_texture!
  end

  def rows=(val : Int64)
    return if @rows == val
    @rows = val
    refresh_texture!
  end

  def cell_inset=(val : Float64)
    return if @cell_inset == val
    @cell_inset = val
    refresh_texture!
  end

  def corner_radius=(val : Float64)
    return if @corner_radius == val
    @corner_radius = val
    refresh_texture!
  end

  def build_svg_body(io : IO, size : Float64, fg : String, bg : String) : Void
    cols = Math.max(@columns.to_i32, 1)
    rws = Math.max(@rows.to_i32, 1)
    cell_w = size / cols
    cell_h = size / rws
    inset = @cell_inset.clamp(0.0, Math.min(cell_w, cell_h) * 0.45)

    (0...rws).each do |row|
      (0...cols).each do |col|
        next unless (row + col).even?
        x = col * cell_w + inset
        y = row * cell_h + inset
        w = Math.max(cell_w - inset * 2.0, 1.0)
        h = Math.max(cell_h - inset * 2.0, 1.0)
        if @corner_radius > 0.0
          io << %(  <rect x="#{fmt(x)}" y="#{fmt(y)}" width="#{fmt(w)}" height="#{fmt(h)}" rx="#{fmt(@corner_radius)}" fill="#{fg}"/>\n)
        else
          io << %(  <rect x="#{fmt(x)}" y="#{fmt(y)}" width="#{fmt(w)}" height="#{fmt(h)}" fill="#{fg}"/>\n)
        end
      end
    end
  end
end

# Procedural Zig-Zag / Chevron band pattern generator.
@[Tool]
resource ZigZagPattern < PatternGenerator do
  @[Export(range: 1..16, step: 1)]
  property peaks : Int64 = 2_i64

  @[Export(range: 1..16, step: 1)]
  property bands : Int64 = 2_i64

  @[Export(range: 2.0..100.0, step: 1.0)]
  property amplitude : Float64 = 20.0

  @[Export(range: 1.0..50.0, step: 0.5)]
  property thickness : Float64 = 12.0

  def peaks=(val : Int64)
    return if @peaks == val
    @peaks = val
    refresh_texture!
  end

  def bands=(val : Int64)
    return if @bands == val
    @bands = val
    refresh_texture!
  end

  def amplitude=(val : Float64)
    return if @amplitude == val
    @amplitude = val
    refresh_texture!
  end

  def thickness=(val : Float64)
    return if @thickness == val
    @thickness = val
    refresh_texture!
  end

  def build_svg_body(io : IO, size : Float64, fg : String, bg : String) : Void
    pks = Math.max(@peaks.to_i32, 1)
    bnds = Math.max(@bands.to_i32, 1)
    seg_w = size / pks
    band_h = size / bnds
    amp = @amplitude
    stroke_w = Math.max(@thickness, 1.0)

    (-1..bnds).each do |b|
      base_y = (b + 0.5) * band_h
      d = String.build do |s|
        s << "M #{fmt(-seg_w)} #{fmt(base_y + amp * 0.5)}"
        (-1..(pks + 1)).each do |p|
          x_mid = (p + 0.5) * seg_w
          x_end = (p + 1.0) * seg_w
          s << " L #{fmt(x_mid)} #{fmt(base_y - amp * 0.5)}"
          s << " L #{fmt(x_end)} #{fmt(base_y + amp * 0.5)}"
        end
      end
      io << %(  <path d="#{d}" fill="none" stroke="#{fg}" stroke-width="#{fmt(stroke_w)}" stroke-linejoin="miter" stroke-linecap="square"/>\n)
    end
  end
end

# Procedural Sine / Bezier Wave band pattern generator.
@[Tool]
resource WavePattern < PatternGenerator do
  @[Export(range: 1..16, step: 1)]
  property waves : Int64 = 2_i64

  @[Export(range: 1..16, step: 1)]
  property bands : Int64 = 2_i64

  @[Export(range: 1.0..80.0, step: 1.0)]
  property amplitude : Float64 = 16.0

  @[Export(range: 1.0..50.0, step: 0.5)]
  property thickness : Float64 = 10.0

  def waves=(val : Int64)
    return if @waves == val
    @waves = val
    refresh_texture!
  end

  def bands=(val : Int64)
    return if @bands == val
    @bands = val
    refresh_texture!
  end

  def amplitude=(val : Float64)
    return if @amplitude == val
    @amplitude = val
    refresh_texture!
  end

  def thickness=(val : Float64)
    return if @thickness == val
    @thickness = val
    refresh_texture!
  end

  def build_svg_body(io : IO, size : Float64, fg : String, bg : String) : Void
    wvs = Math.max(@waves.to_i32, 1)
    bnds = Math.max(@bands.to_i32, 1)
    wave_w = size / wvs
    half_w = wave_w * 0.5
    q_w = wave_w * 0.25
    band_h = size / bnds
    amp = @amplitude
    stroke_w = Math.max(@thickness, 1.0)

    (-1..bnds).each do |b|
      base_y = (b + 0.5) * band_h
      d = String.build do |s|
        s << "M #{fmt(-wave_w)} #{fmt(base_y)}"
        (-1..(wvs + 1)).each do |w|
          x0 = w * wave_w
          s << " Q #{fmt(x0 + q_w)} #{fmt(base_y - amp)}, #{fmt(x0 + half_w)} #{fmt(base_y)}"
          s << " Q #{fmt(x0 + half_w + q_w)} #{fmt(base_y + amp)}, #{fmt(x0 + wave_w)} #{fmt(base_y)}"
        end
      end
      io << %(  <path d="#{d}" fill="none" stroke="#{fg}" stroke-width="#{fmt(stroke_w)}" stroke-linecap="round"/>\n)
    end
  end
end

# Procedural Concentric Ring / Target / Seigaiha pattern generator.
@[Tool]
resource RingPattern < PatternGenerator do
  @[Export(range: 1..16, step: 1)]
  property ring_count : Int64 = 3_i64

  @[Export(range: 1.0..40.0, step: 0.5)]
  property ring_width : Float64 = 8.0

  @[Export(range: 5.0..100.0, step: 1.0)]
  property max_radius : Float64 = 45.0

  @[Export]
  property corner_overlays : Bool = false

  def ring_count=(val : Int64)
    return if @ring_count == val
    @ring_count = val
    refresh_texture!
  end

  def ring_width=(val : Float64)
    return if @ring_width == val
    @ring_width = val
    refresh_texture!
  end

  def max_radius=(val : Float64)
    return if @max_radius == val
    @max_radius = val
    refresh_texture!
  end

  def corner_overlays=(val : Bool)
    return if @corner_overlays == val
    @corner_overlays = val
    refresh_texture!
  end

  def build_svg_body(io : IO, size : Float64, fg : String, bg : String) : Void
    cnt = Math.max(@ring_count.to_i32, 1)
    rw = Math.max(@ring_width, 1.0)
    max_r = Math.max(@max_radius, 2.0)
    cx = size * 0.5
    cy = size * 0.5

    emit_concentric(io, cx, cy, cnt, max_r, rw, fg)

    if @corner_overlays
      [{0.0, 0.0}, {size, 0.0}, {0.0, size}, {size, size}].each do |corner_x, corner_y|
        emit_concentric(io, corner_x, corner_y, cnt, max_r, rw, fg)
      end
    end
  end

  private def emit_concentric(io : IO, cx : Float64, cy : Float64, cnt : Int32, max_r : Float64, rw : Float64, fg : String) : Void
    (1..cnt).each do |i|
      r = max_r * (i.to_f64 / cnt)
      io << %(  <circle cx="#{fmt(cx)}" cy="#{fmt(cy)}" r="#{fmt(r)}" fill="none" stroke="#{fg}" stroke-width="#{fmt(rw)}"/>\n)
    end
  end
end

# Procedural Honeycomb / Hexagon Grid pattern generator.
@[Tool]
resource HexagonPattern < PatternGenerator do
  @[Export(range: 1..16, step: 1)]
  property columns : Int64 = 2_i64

  @[Export(range: 1..16, step: 1)]
  property rows : Int64 = 2_i64

  @[Export(range: 4.0..80.0, step: 0.5)]
  property hex_radius : Float64 = 22.0

  @[Export(range: 0.0..30.0, step: 0.5)]
  property stroke_width : Float64 = 5.0

  @[Export]
  property flat_top : Bool = false

  def columns=(val : Int64)
    return if @columns == val
    @columns = val
    refresh_texture!
  end

  def rows=(val : Int64)
    return if @rows == val
    @rows = val
    refresh_texture!
  end

  def hex_radius=(val : Float64)
    return if @hex_radius == val
    @hex_radius = val
    refresh_texture!
  end

  def stroke_width=(val : Float64)
    return if @stroke_width == val
    @stroke_width = val
    refresh_texture!
  end

  def flat_top=(val : Bool)
    return if @flat_top == val
    @flat_top = val
    refresh_texture!
  end

  def build_svg_body(io : IO, size : Float64, fg : String, bg : String) : Void
    cols = Math.max(@columns.to_i32, 1)
    rws = Math.max(@rows.to_i32, 1)
    cell_w = size / cols
    cell_h = size / rws
    r = Math.max(@hex_radius, 2.0)

    (0...rws).each do |row|
      offset_x = row.odd? ? (cell_w * 0.5) : 0.0
      cy = (row + 0.5) * cell_h
      (0...cols).each do |col|
        cx = (col + 0.5) * cell_w + offset_x
        emit_hexagon(io, cx, cy, r, fg)
        if cx + r > size
          emit_hexagon(io, cx - size, cy, r, fg)
        end
      end
    end
  end

  private def emit_hexagon(io : IO, cx : Float64, cy : Float64, r : Float64, fg : String) : Void
    pts = (0...6).map do |i|
      angle_deg = @flat_top ? (60.0 * i) : (60.0 * i - 30.0)
      rad = angle_deg * Math::PI / 180.0
      px = cx + r * Math.cos(rad)
      py = cy + r * Math.sin(rad)
      "#{fmt(px)},#{fmt(py)}"
    end.join(" ")

    if @stroke_width > 0.0
      io << %(  <polygon points="#{pts}" fill="none" stroke="#{fg}" stroke-width="#{fmt(@stroke_width)}" stroke-linejoin="round"/>\n)
    else
      io << %(  <polygon points="#{pts}" fill="#{fg}"/>\n)
    end
  end
end

# Procedural Argyle / Diamond Lattice pattern generator.
@[Tool]
resource DiamondPattern < PatternGenerator do
  @[Export(range: 1..16, step: 1)]
  property columns : Int64 = 2_i64

  @[Export(range: 1..16, step: 1)]
  property rows : Int64 = 2_i64

  @[Export(range: 0.1..1.5, step: 0.05)]
  property diamond_scale : Float64 = 0.85

  @[Export(range: 0.0..25.0, step: 0.5)]
  property hollow_stroke : Float64 = 0.0

  def columns=(val : Int64)
    return if @columns == val
    @columns = val
    refresh_texture!
  end

  def rows=(val : Int64)
    return if @rows == val
    @rows = val
    refresh_texture!
  end

  def diamond_scale=(val : Float64)
    return if @diamond_scale == val
    @diamond_scale = val
    refresh_texture!
  end

  def hollow_stroke=(val : Float64)
    return if @hollow_stroke == val
    @hollow_stroke = val
    refresh_texture!
  end

  def build_svg_body(io : IO, size : Float64, fg : String, bg : String) : Void
    cols = Math.max(@columns.to_i32, 1)
    rws = Math.max(@rows.to_i32, 1)
    cell_w = size / cols
    cell_h = size / rws
    rx = (cell_w * 0.5) * @diamond_scale
    ry = (cell_h * 0.5) * @diamond_scale

    (0...rws).each do |row|
      cy = (row + 0.5) * cell_h
      (0...cols).each do |col|
        cx = (col + 0.5) * cell_w
        pts = "#{fmt(cx)},#{fmt(cy - ry)} #{fmt(cx + rx)},#{fmt(cy)} #{fmt(cx)},#{fmt(cy + ry)} #{fmt(cx - rx)},#{fmt(cy)}"
        if @hollow_stroke > 0.0
          io << %(  <polygon points="#{pts}" fill="none" stroke="#{fg}" stroke-width="#{fmt(@hollow_stroke)}"/>\n)
        else
          io << %(  <polygon points="#{pts}" fill="#{fg}"/>\n)
        end
      end
    end
  end
end

# Procedural Plus / Cross / X-mark grid pattern generator.
@[Tool]
resource CrossPattern < PatternGenerator do
  @[Export(range: 1..16, step: 1)]
  property columns : Int64 = 2_i64

  @[Export(range: 1..16, step: 1)]
  property rows : Int64 = 2_i64

  @[Export(range: 4.0..80.0, step: 1.0)]
  property arm_length : Float64 = 28.0

  @[Export(range: 1.0..40.0, step: 0.5)]
  property arm_thickness : Float64 = 8.0

  @[Export]
  property stagger : Bool = true

  @[Export]
  property diagonal_x : Bool = false

  def columns=(val : Int64)
    return if @columns == val
    @columns = val
    refresh_texture!
  end

  def rows=(val : Int64)
    return if @rows == val
    @rows = val
    refresh_texture!
  end

  def arm_length=(val : Float64)
    return if @arm_length == val
    @arm_length = val
    refresh_texture!
  end

  def arm_thickness=(val : Float64)
    return if @arm_thickness == val
    @arm_thickness = val
    refresh_texture!
  end

  def stagger=(val : Bool)
    return if @stagger == val
    @stagger = val
    refresh_texture!
  end

  def diagonal_x=(val : Bool)
    return if @diagonal_x == val
    @diagonal_x = val
    refresh_texture!
  end

  def build_svg_body(io : IO, size : Float64, fg : String, bg : String) : Void
    cols = Math.max(@columns.to_i32, 1)
    rws = Math.max(@rows.to_i32, 1)
    cell_w = size / cols
    cell_h = size / rws
    len = Math.max(@arm_length, 2.0)
    thick = Math.max(@arm_thickness, 1.0)

    (0...rws).each do |row|
      offset_x = (@stagger && row.odd?) ? (cell_w * 0.5) : 0.0
      cy = (row + 0.5) * cell_h
      (0...cols).each do |col|
        cx = (col + 0.5) * cell_w + offset_x
        emit_cross(io, cx, cy, len, thick, fg)
        if cx + len * 0.5 > size
          emit_cross(io, cx - size, cy, len, thick, fg)
        end
      end
    end
  end

  private def emit_cross(io : IO, cx : Float64, cy : Float64, len : Float64, thick : Float64, fg : String) : Void
    half_len = len * 0.5
    half_thick = thick * 0.5
    if @diagonal_x
      io << %(  <g transform="rotate(45,#{fmt(cx)},#{fmt(cy)})">\n)
      io << %(    <rect x="#{fmt(cx - half_len)}" y="#{fmt(cy - half_thick)}" width="#{fmt(len)}" height="#{fmt(thick)}" fill="#{fg}"/>\n)
      io << %(    <rect x="#{fmt(cx - half_thick)}" y="#{fmt(cy - half_len)}" width="#{fmt(thick)}" height="#{fmt(len)}" fill="#{fg}"/>\n)
      io << %(  </g>\n)
    else
      io << %(  <rect x="#{fmt(cx - half_len)}" y="#{fmt(cy - half_thick)}" width="#{fmt(len)}" height="#{fmt(thick)}" fill="#{fg}"/>\n)
      io << %(  <rect x="#{fmt(cx - half_thick)}" y="#{fmt(cy - half_len)}" width="#{fmt(thick)}" height="#{fmt(len)}" fill="#{fg}"/>\n)
    end
  end
end

# Procedural Multi-Point Star / Sparkle burst pattern generator.
@[Tool]
resource StarPattern < PatternGenerator do
  @[Export(range: 1..16, step: 1)]
  property columns : Int64 = 2_i64

  @[Export(range: 1..16, step: 1)]
  property rows : Int64 = 2_i64

  @[Export(range: 3..12, step: 1)]
  property points : Int64 = 4_i64

  @[Export(range: 4.0..80.0, step: 1.0)]
  property outer_radius : Float64 = 22.0

  @[Export(range: 1.0..60.0, step: 0.5)]
  property inner_radius : Float64 = 8.0

  @[Export]
  property stagger : Bool = true

  def columns=(val : Int64)
    return if @columns == val
    @columns = val
    refresh_texture!
  end

  def rows=(val : Int64)
    return if @rows == val
    @rows = val
    refresh_texture!
  end

  def points=(val : Int64)
    return if @points == val
    @points = val
    refresh_texture!
  end

  def outer_radius=(val : Float64)
    return if @outer_radius == val
    @outer_radius = val
    refresh_texture!
  end

  def inner_radius=(val : Float64)
    return if @inner_radius == val
    @inner_radius = val
    refresh_texture!
  end

  def stagger=(val : Bool)
    return if @stagger == val
    @stagger = val
    refresh_texture!
  end

  def build_svg_body(io : IO, size : Float64, fg : String, bg : String) : Void
    cols = Math.max(@columns.to_i32, 1)
    rws = Math.max(@rows.to_i32, 1)
    pts_count = Math.max(@points.to_i32, 3)
    cell_w = size / cols
    cell_h = size / rws
    r_out = Math.max(@outer_radius, 2.0)
    r_in = Math.max(@inner_radius, 0.5)

    (0...rws).each do |row|
      offset_x = (@stagger && row.odd?) ? (cell_w * 0.5) : 0.0
      cy = (row + 0.5) * cell_h
      (0...cols).each do |col|
        cx = (col + 0.5) * cell_w + offset_x
        emit_star(io, cx, cy, pts_count, r_out, r_in, fg)
        if cx + r_out > size
          emit_star(io, cx - size, cy, pts_count, r_out, r_in, fg)
        end
      end
    end
  end

  private def emit_star(io : IO, cx : Float64, cy : Float64, pts_count : Int32, r_out : Float64, r_in : Float64, fg : String) : Void
    total_verts = pts_count * 2
    pts = (0...total_verts).map do |i|
      r = i.even? ? r_out : r_in
      angle = (i.to_f64 * Math::PI / pts_count) - (Math::PI * 0.5)
      px = cx + r * Math.cos(angle)
      py = cy + r * Math.sin(angle)
      "#{fmt(px)},#{fmt(py)}"
    end.join(" ")
    io << %(  <polygon points="#{pts}" fill="#{fg}"/>\n)
  end
end

# Procedural Running-Bond Brick / Subway Tile pattern generator.
@[Tool]
resource BrickPattern < PatternGenerator do
  @[Export(range: 1..16, step: 1)]
  property columns : Int64 = 2_i64

  @[Export(range: 1..32, step: 1)]
  property rows : Int64 = 4_i64

  @[Export(range: 1.0..30.0, step: 0.5)]
  property mortar_gap : Float64 = 5.0

  @[Export(range: 0.0..1.0, step: 0.05)]
  property row_offset : Float64 = 0.5

  @[Export(range: 0.0..20.0, step: 0.5)]
  property corner_radius : Float64 = 2.0

  def columns=(val : Int64)
    return if @columns == val
    @columns = val
    refresh_texture!
  end

  def rows=(val : Int64)
    return if @rows == val
    @rows = val
    refresh_texture!
  end

  def mortar_gap=(val : Float64)
    return if @mortar_gap == val
    @mortar_gap = val
    refresh_texture!
  end

  def row_offset=(val : Float64)
    return if @row_offset == val
    @row_offset = val
    refresh_texture!
  end

  def corner_radius=(val : Float64)
    return if @corner_radius == val
    @corner_radius = val
    refresh_texture!
  end

  def build_svg_body(io : IO, size : Float64, fg : String, bg : String) : Void
    cols = Math.max(@columns.to_i32, 1)
    rws = Math.max(@rows.to_i32, 1)
    cell_w = size / cols
    cell_h = size / rws
    gap = @mortar_gap.clamp(0.0, Math.min(cell_w, cell_h) * 0.8)
    brick_w = Math.max(cell_w - gap, 1.0)
    brick_h = Math.max(cell_h - gap, 1.0)

    (0...rws).each do |row|
      shift = row.odd? ? (cell_w * @row_offset) : 0.0
      y = row * cell_h + gap * 0.5
      (-1..cols).each do |col|
        x = col * cell_w + shift + gap * 0.5
        next if x + brick_w <= 0.0 || x >= size
        if @corner_radius > 0.0
          io << %(  <rect x="#{fmt(x)}" y="#{fmt(y)}" width="#{fmt(brick_w)}" height="#{fmt(brick_h)}" rx="#{fmt(@corner_radius)}" fill="#{fg}"/>\n)
        else
          io << %(  <rect x="#{fmt(x)}" y="#{fmt(y)}" width="#{fmt(brick_w)}" height="#{fmt(brick_h)}" fill="#{fg}"/>\n)
        end
      end
    end
  end
end

# Procedural Houndstooth textile weave pattern generator.
@[Tool]
resource HoundstoothPattern < PatternGenerator do
  @[Export(range: 1..8, step: 1)]
  property subdivisions : Int64 = 2_i64

  @[Export(range: 0.1..1.0, step: 0.05)]
  property tooth_slant : Float64 = 0.5

  def subdivisions=(val : Int64)
    return if @subdivisions == val
    @subdivisions = val
    refresh_texture!
  end

  def tooth_slant=(val : Float64)
    return if @tooth_slant == val
    @tooth_slant = val
    refresh_texture!
  end

  def build_svg_body(io : IO, size : Float64, fg : String, bg : String) : Void
    subs = Math.max(@subdivisions.to_i32, 1)
    tile = size / subs
    half = tile * 0.5
    q = half * @tooth_slant.clamp(0.1, 1.0)

    (0...subs).each do |row|
      y0 = row * tile
      (0...subs).each do |col|
        x0 = col * tile
        # Core square body
        io << %(  <rect x="#{fmt(x0)}" y="#{fmt(y0)}" width="#{fmt(half)}" height="#{fmt(half)}" fill="#{fg}"/>\n)
        # Diagonal tooth extensions
        pts1 = "#{fmt(x0 + half)},#{fmt(y0)} #{fmt(x0 + tile)},#{fmt(y0)} #{fmt(x0 + half)},#{fmt(y0 + q)}"
        pts2 = "#{fmt(x0)},#{fmt(y0 + half)} #{fmt(x0 + q)},#{fmt(y0 + half)} #{fmt(x0)},#{fmt(y0 + tile)}"
        pts3 = "#{fmt(x0 + half)},#{fmt(y0 + half)} #{fmt(x0 + tile)},#{fmt(y0 + half)} #{fmt(x0 + half + q)},#{fmt(y0 + tile)} #{fmt(x0 + half)},#{fmt(y0 + tile)}"
        io << %(  <polygon points="#{pts1}" fill="#{fg}"/>\n)
        io << %(  <polygon points="#{pts2}" fill="#{fg}"/>\n)
        io << %(  <polygon points="#{pts3}" fill="#{fg}"/>\n)
      end
    end
  end
end

# Procedural Halftone Dot Gradient pattern generator.
@[Tool]
resource HalftonePattern < PatternGenerator do
  @[Export(range: 2..32, step: 1)]
  property columns : Int64 = 6_i64

  @[Export(range: 2..32, step: 1)]
  property rows : Int64 = 6_i64

  @[Export(range: 0.5..30.0, step: 0.5)]
  property min_radius : Float64 = 2.0

  @[Export(range: 1.0..50.0, step: 0.5)]
  property max_radius : Float64 = 9.0

  @[Export]
  property radial_falloff : Bool = false

  def columns=(val : Int64)
    return if @columns == val
    @columns = val
    refresh_texture!
  end

  def rows=(val : Int64)
    return if @rows == val
    @rows = val
    refresh_texture!
  end

  def min_radius=(val : Float64)
    return if @min_radius == val
    @min_radius = val
    refresh_texture!
  end

  def max_radius=(val : Float64)
    return if @max_radius == val
    @max_radius = val
    refresh_texture!
  end

  def radial_falloff=(val : Bool)
    return if @radial_falloff == val
    @radial_falloff = val
    refresh_texture!
  end

  def build_svg_body(io : IO, size : Float64, fg : String, bg : String) : Void
    cols = Math.max(@columns.to_i32, 2)
    rws = Math.max(@rows.to_i32, 2)
    cell_w = size / cols
    cell_h = size / rws
    half_s = size * 0.5
    max_dist = Math.sqrt(half_s * half_s * 2.0)

    (0...rws).each do |row|
      cy = (row + 0.5) * cell_h
      (0...cols).each do |col|
        cx = (col + 0.5) * cell_w
        t = if @radial_falloff
              dx = cx - half_s
              dy = cy - half_s
              1.0 - (Math.sqrt(dx * dx + dy * dy) / max_dist).clamp(0.0, 1.0)
            else
              # Smooth periodic vertical wave so top and bottom edges tile seamlessly
              0.5 * (1.0 - Math.cos((cy / size) * 2.0 * Math::PI))
            end
        r = @min_radius + (@max_radius - @min_radius) * t
        io << %(  <circle cx="#{fmt(cx)}" cy="#{fmt(cy)}" r="#{fmt(Math.max(r, 0.5))}" fill="#{fg}"/>\n)
      end
    end
  end
end

# All-in-one multi-mode procedural pattern generator allowing users to switch between
# all 13 procedural pattern types with a single dropdown in the Godot Inspector.
@[Tool]
resource CustomPatternGenerator < PatternGenerator do
  enum PatternKind
    PolkaDots   =  0
    Stripes     =  1
    Checkers    =  2
    ZigZag      =  3
    Waves       =  4
    Rings       =  5
    Hexagons    =  6
    Diamonds    =  7
    Crosses     =  8
    Stars       =  9
    Bricks      = 10
    Houndstooth = 11
    Halftone    = 12
  end

  @[ExportEnum(CustomPatternGenerator::PatternKind)]
  property kind : PatternKind = PatternKind::PolkaDots

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

  def kind=(val : PatternKind)
    return if @kind == val
    @kind = val
    refresh_texture!
  end

  def columns=(val : Int64)
    return if @columns == val
    @columns = val
    refresh_texture!
  end

  def rows=(val : Int64)
    return if @rows == val
    @rows = val
    refresh_texture!
  end

  def primary_size=(val : Float64)
    return if @primary_size == val
    @primary_size = val
    refresh_texture!
  end

  def secondary_size=(val : Float64)
    return if @secondary_size == val
    @secondary_size = val
    refresh_texture!
  end

  def stagger=(val : Bool)
    return if @stagger == val
    @stagger = val
    refresh_texture!
  end

  def build_svg_body(io : IO, size : Float64, fg : String, bg : String) : Void
    case @kind
    when PatternKind::PolkaDots
      gen = PolkaDotPattern.new
      gen.columns = @columns
      gen.rows = @rows
      gen.dot_radius = @primary_size
      gen.ring_thickness = @secondary_size
      gen.stagger = @stagger
      gen.build_svg_body(io, size, fg, bg)
    when PatternKind::Stripes
      gen = StripePattern.new
      gen.stripe_count = @columns
      gen.duty_cycle = (@primary_size / 100.0).clamp(0.05, 0.95)
      gen.angle_degrees = @secondary_size
      gen.crosshatch = !@stagger
      gen.build_svg_body(io, size, fg, bg)
    when PatternKind::Checkers
      gen = CheckerPattern.new
      gen.columns = @columns
      gen.rows = @rows
      gen.cell_inset = @secondary_size
      gen.build_svg_body(io, size, fg, bg)
    when PatternKind::ZigZag
      gen = ZigZagPattern.new
      gen.peaks = @columns
      gen.bands = @rows
      gen.amplitude = @primary_size
      gen.thickness = Math.max(@secondary_size, 1.0)
      gen.build_svg_body(io, size, fg, bg)
    when PatternKind::Waves
      gen = WavePattern.new
      gen.waves = @columns
      gen.bands = @rows
      gen.amplitude = @primary_size
      gen.thickness = Math.max(@secondary_size, 1.0)
      gen.build_svg_body(io, size, fg, bg)
    when PatternKind::Rings
      gen = RingPattern.new
      gen.ring_count = @columns
      gen.max_radius = @primary_size
      gen.ring_width = Math.max(@secondary_size, 1.0)
      gen.corner_overlays = @stagger
      gen.build_svg_body(io, size, fg, bg)
    when PatternKind::Hexagons
      gen = HexagonPattern.new
      gen.columns = @columns
      gen.rows = @rows
      gen.hex_radius = @primary_size
      gen.stroke_width = @secondary_size
      gen.build_svg_body(io, size, fg, bg)
    when PatternKind::Diamonds
      gen = DiamondPattern.new
      gen.columns = @columns
      gen.rows = @rows
      gen.diamond_scale = (@primary_size / 25.0).clamp(0.1, 1.5)
      gen.hollow_stroke = @secondary_size
      gen.build_svg_body(io, size, fg, bg)
    when PatternKind::Crosses
      gen = CrossPattern.new
      gen.columns = @columns
      gen.rows = @rows
      gen.arm_length = @primary_size
      gen.arm_thickness = Math.max(@secondary_size, 1.0)
      gen.stagger = @stagger
      gen.build_svg_body(io, size, fg, bg)
    when PatternKind::Stars
      gen = StarPattern.new
      gen.columns = @columns
      gen.rows = @rows
      gen.outer_radius = @primary_size
      gen.inner_radius = Math.max(@secondary_size, 1.0)
      gen.stagger = @stagger
      gen.build_svg_body(io, size, fg, bg)
    when PatternKind::Bricks
      gen = BrickPattern.new
      gen.columns = @columns
      gen.rows = @rows
      gen.mortar_gap = Math.max(@secondary_size, 1.0)
      gen.build_svg_body(io, size, fg, bg)
    when PatternKind::Houndstooth
      gen = HoundstoothPattern.new
      gen.subdivisions = @columns
      gen. build_svg_body(io, size, fg, bg)
    when PatternKind::Halftone
      gen = HalftonePattern.new
      gen.columns = @columns
      gen.rows = @rows
      gen.max_radius = @primary_size
      gen.min_radius = Math.max(@secondary_size, 0.5)
      gen.radial_falloff = @stagger
      gen.build_svg_body(io, size, fg, bg)
    end
  end
end
