require "spec"
require "../src/main"

describe PatternMaterialAddon do
  it "defines addon version" do
    PatternMaterialAddon::VERSION.should_not be_empty
  end
end

describe SvgSpritesheetBuilder do
  it "registers SvgSpritesheetBuilder and SpritesheetAtlas in Godot::ClassRegistry" do
    builder_entry = Godot::ClassRegistry.find("SvgSpritesheetBuilder")
    builder_entry.should_not be_nil
    builder_entry.not_nil!.parent_name.should eq("Node")
    builder_entry.not_nil!.is_tool.should be_true

    atlas_entry = Godot::ClassRegistry.find("SpritesheetAtlas")
    atlas_entry.should_not be_nil
    atlas_entry.not_nil!.parent_name.should eq("Resource")
  end

  it "normalizes FontAwesome duotone SVGs by making opacity paths white and keeping black paths black" do
    raw_svg = %(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640"><path opacity=".4" fill="currentColor" d="M144 160z"/><path fill="currentColor" d="M160 144z"/></svg>)
    normalized = SvgSpritesheetBuilder.normalize_svg(raw_svg)
    normalized.should eq(%(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640"><path fill="#ffffff" d="M144 160z"/><path fill="currentColor" d="M160 144z"/></svg>))
  end
end

describe "Faces and Glyphs Spritesheet Resources" do
  it "provides String/Char indexing and ItemInfo metadata for Faces" do
    Faces.count.should eq(105)
    Faces.hframes.should eq(12)
    Faces.vframes.should eq(9)
    Faces["angry-horns"].should eq(0)
    Faces["smile"].should eq(86)
    Faces["happy"].should eq(86)
    Faces["nonexistent"]?.should be_nil

    info = Faces.info("smile")
    info.index.should eq(86)
    info.id.should eq("face-smile")
    info.key.should eq("smile")
  end

  it "provides explicit prefix lookup and ItemInfo metadata for Glyphs (circle and square variants)" do
    Glyphs.count.should eq(307)
    Glyphs.hframes.should eq(12)
    Glyphs.vframes.should eq(26)
    Glyphs.cell_px_size.should eq(24)
    Glyphs["circle-0"].should eq(0)
    Glyphs["circle-a"].should eq(10)
    Glyphs["square-a"].should eq(172)
    Glyphs["a"]?.should be_nil
  end
end

describe "Patterns, Palette, and UniversalMaterial" do
  it "indexes all 88 SVG patterns in addons/pattern_material/textures/patterns with normalized key lookup" do
    Patterns.count.should eq(88)
    Patterns["moroccan"].should eq("res://addons/pattern_material/textures/patterns/moroccan.svg")
    Patterns["hexagons"].should eq("res://addons/pattern_material/textures/patterns/hexagons.svg")
    Patterns["zig-zag"].should eq("res://addons/pattern_material/textures/patterns/zig_zag.svg")
    Patterns["zig_zag.svg"].should eq("res://addons/pattern_material/textures/patterns/zig_zag.svg")
    Patterns["res://textures/patterns/moroccan.svg"].should eq("res://addons/pattern_material/textures/patterns/moroccan.svg")
    Patterns["res://addons/pattern_material/textures/patterns/moroccan.svg"].should eq("res://addons/pattern_material/textures/patterns/moroccan.svg")
    Patterns[0].should eq("res://addons/pattern_material/textures/patterns/4_point_stars.svg")
    Patterns["nonexistent"]?.should be_nil
    File.exists?("addons/pattern_material/textures/patterns/moroccan.svg").should be_true
  end

  it "exposes all 32 Afterlife 98 colors in Palette by index and name" do
    Palette.count.should eq(32)
    Palette[0].r.should be_close(47.0 / 255.0, 0.001)
    Palette[0].g.should be_close(37.0 / 255.0, 0.001)
    Palette[0].b.should be_close(86.0 / 255.0, 0.001)
    Palette["deep_indigo"].should eq(Palette[0])
    Palette["white"].should eq(Palette[5])
    Palette["hot-watermelon"].should eq(Palette[18])
    Palette["nonexistent"]?.should be_nil
  end

  it "configures UniversalMaterial / PatternMaterial parameters fluently across Faces, Glyphs, Patterns, Generators, Palette, and shader effects" do
    umat = PatternMaterial.new
    umat
      .set_face("smile")
      .set_pattern("moroccan")
      .set_colors(fg: "hot_watermelon", bg: "ice_aqua", outline: "white", unreplaced: "deep_indigo")
      .set_3d_surface(UniversalMaterial::ProjectionMode::WorldTriplanar, use_base_texture: true, tile_base_texture: true)
      .set_outline(enabled: true, width: 3.5, mode: UniversalMaterial::OutlineMode::Center, boil_amp: 0.2)
      .set_bevel(enabled: true, strength: 0.6)
      .set_fresnel(enabled: true, power: 2.5, invert_pattern: true)
      .set_drop_shadow(enabled: true)
      .set_dither(enabled: true, strength: 0.4, pixel_size: 2.0)
      .set_dissolve(amount: 0.25)
      .set_retro_crt(glitch_intensity: 0.15, scanline_strength: 0.3)
      .set_transparency(master_opacity: 0.75, pattern_alpha_affects_surface: true, outline_ignores_master_opacity: true, opacity_dither_enabled: false)
      .set_backdrop_fx(
        blend_mode: UniversalMaterial::BackdropBlendMode::DuotonePaletteMap,
        refraction: 0.3,
        pixel_size: 4.0,
        blur_lod: 1.5,
        chromatic_aberration: 0.01
      )
      .set_vertex_fx(
        billboard: UniversalMaterial::BillboardMode::YBillboard,
        motion: UniversalMaterial::VertexMotionMode::SurfaceWaves3D,
        vertex_snap: true
      )

    umat.get_param?("frame").should eq(86_i64)
    umat.get_param?("custom_pattern").should eq("res://addons/pattern_material/textures/patterns/moroccan.svg")
    umat.get_param?("remap_unreplaced").should eq(true)
    umat.get_param?("perspective_normals").should eq(2_i64)
    umat.get_param?("tile_base_texture").should eq(true)
    umat.get_param?("outline_boil_amp").should eq(0.2)
    umat.get_param?("bevel_enabled").should eq(true)
    umat.get_param?("fresnel_enabled").should eq(true)
    umat.get_param?("shadow_enabled").should eq(true)
    umat.get_param?("dither_enabled").should eq(true)
    umat.get_param?("dissolve_amount").should eq(0.25)
    umat.get_param?("glitch_intensity").should eq(0.15)
    umat.get_param?("master_opacity").should eq(0.75)
    umat.get_param?("pattern_alpha_affects_surface").should eq(true)
    umat.get_param?("outline_ignores_master_opacity").should eq(true)
    umat.get_param?("backdrop_blend_mode").should eq(5_i64)
    umat.get_param?("backdrop_refraction").should eq(0.3)
    umat.get_param?("backdrop_pixel_size").should eq(4.0)
    umat.get_param?("backdrop_blur_lod").should eq(1.5)
    umat.get_param?("backdrop_chromatic_aberration").should eq(0.01)
    umat.get_param?("billboard_mode").should eq(2_i64)
    umat.get_param?("vertex_motion_mode").should eq(1_i64)
    umat.get_param?("vertex_snap_enabled").should eq(true)

    umat.set_glyph("circle-a")
    umat.get_param?("frame").should eq(10_i64)
    umat.get_param?("hframes").should eq(12_i64)
    umat.get_param?("vframes").should eq(26_i64)

    dots = Patterns.polka_dots(dot_radius: 15.0, columns: 3, rows: 3)
    umat.set_generator(dots)
    umat.generator.should eq(dots)
    umat.get_param?("custom_pattern").should eq("PolkaDotPattern")
  end

  it "includes all universal material uniform groups and presets in addons/pattern_material" do
    shader_code = File.read("addons/pattern_material/shaders/pattern_replace.gdshader")
    shader_code.includes?("uniform bool use_base_texture").should be_true
    shader_code.includes?("uniform bool tile_base_texture").should be_true
    shader_code.includes?("group_uniforms Base_Color_Remap;").should be_true
    shader_code.includes?("group_uniforms Bevel_And_Rim;").should be_true
    shader_code.includes?("group_uniforms Drop_Shadow;").should be_true
    shader_code.includes?("group_uniforms Stylization_FX;").should be_true
    shader_code.includes?("group_uniforms Transparency_And_Backdrop;").should be_true
    shader_code.includes?("uniform float master_opacity").should be_true
    shader_code.includes?("uniform bool pattern_alpha_affects_surface").should be_true
    shader_code.includes?("uniform int backdrop_blend_mode").should be_true
    shader_code.includes?("hint_screen_texture").should be_true
    shader_code.includes?("group_uniforms Vertex_FX;").should be_true
    shader_code.includes?("World Triplanar:2,Mesh UV:3,Cylindrical:4").should be_true
    shader_code.includes?("max(rgb.r, max(rgb.g, rgb.b))").should be_true
    shader_code.includes?("min(rgb.r, min(rgb.g, rgb.b))").should be_true
    shader_code.includes?("max(rgb.r, rgb.g, rgb.b)").should be_false
    shader_code.includes?("POSITION =").should be_false
    shader_code.includes?("MODELVIEW_MATRIX =").should be_false

    File.exists?("addons/pattern_material/plugin.cfg").should be_true
    File.exists?("addons/pattern_material/plugin.gd").should be_true
    File.exists?("addons/pattern_material/materials/cutout_character.tres").should be_true
    File.exists?("addons/pattern_material/materials/sticker_glyph.tres").should be_true
    File.exists?("addons/pattern_material/materials/retro_hologram.tres").should be_true
    File.exists?("addons/pattern_material/materials/glass_lens.tres").should be_true
  end

  it "registers PatternMaterialPlugin, PatternShaderMaterial, PatternGeneratorTool, and all 14 PatternGenerator resources with custom Export properties" do
    plugin_entry = Godot::ClassRegistry.find("PatternMaterialPlugin")
    plugin_entry.should_not be_nil
    plugin_entry.not_nil!.parent_name.should eq("EditorPlugin")
    plugin_entry.not_nil!.is_tool.should be_true

    mat_entry = Godot::ClassRegistry.find("PatternShaderMaterial")
    mat_entry.should_not be_nil
    mat_entry.not_nil!.parent_name.should eq("ShaderMaterial")
    mat_entry.not_nil!.is_tool.should be_true

    tool_entry = Godot::ClassRegistry.find("PatternGeneratorTool")
    tool_entry.should_not be_nil
    tool_entry.not_nil!.parent_name.should eq("Node")
    tool_entry.not_nil!.is_tool.should be_true

    base_gen = Godot::ClassRegistry.find("PatternGenerator")
    base_gen.should_not be_nil
    base_gen.not_nil!.parent_name.should eq("ImageTexture")
    base_gen.not_nil!.is_tool.should be_true

    generator_classes = [
      "PolkaDotPattern",
      "StripePattern",
      "CheckerPattern",
      "ZigZagPattern",
      "WavePattern",
      "RingPattern",
      "HexagonPattern",
      "DiamondPattern",
      "CrossPattern",
      "StarPattern",
      "BrickPattern",
      "HoundstoothPattern",
      "HalftonePattern",
      "CustomPatternGenerator",
    ]

    generator_classes.each do |cls_name|
      entry = Godot::ClassRegistry.find(cls_name)
      entry.should_not be_nil
      entry.not_nil!.parent_name.should eq("PatternGenerator")
      entry.not_nil!.is_tool.should be_true
      entry.not_nil!.properties.should_not be_empty
    end
  end

  it "generates valid repeating black-and-white SVGs across all 14 procedural pattern generators" do
    polka = Patterns.polka_dots(dot_radius: 14.0, columns: 3, rows: 3, stagger: true, ring_thickness: 0.0)
    polka_svg = polka.to_svg
    polka_svg.includes?(%(<svg xmlns="http://www.w3.org/2000/svg")).should be_true
    polka_svg.includes?(%(<circle)).should be_true
    polka_svg.includes?(%(fill="#ffffff")).should be_true

    polka_ring = Patterns.polka_dots(dot_radius: 14.0, ring_thickness: 4.0, invert: true)
    polka_ring.to_svg.includes?(%(stroke="#000000" stroke-width="4")).should be_true

    stripes = Patterns.stripes(stripe_count: 6, duty_cycle: 0.4, angle_degrees: 45.0, crosshatch: true)
    stripes_svg = stripes.to_svg
    stripes_svg.includes?(%(rotate(45,50,50))).should be_true
    stripes_svg.includes?(%(rotate(135,50,50))).should be_true

    checkers = Patterns.checkers(columns: 4, rows: 4, cell_inset: 2.0, corner_radius: 3.0)
    checkers.to_svg.includes?(%(rx="3")).should be_true

    zigzag = Patterns.zig_zag(peaks: 3, bands: 2, amplitude: 18.0, thickness: 8.0)
    zigzag.to_svg.includes?(%(<path d="M )).should be_true

    waves = Patterns.waves(waves: 3, bands: 2, amplitude: 14.0, thickness: 6.0)
    waves.to_svg.includes?(%( Q )).should be_true

    rings = Patterns.rings(ring_count: 4, ring_width: 5.0, max_radius: 40.0, corner_overlays: true)
    rings.to_svg.includes?(%(stroke-width="5")).should be_true

    hexes = Patterns.hexagons(columns: 2, rows: 2, hex_radius: 20.0, stroke_width: 4.0, flat_top: true)
    hexes.to_svg.includes?(%(<polygon points=)).should be_true

    diamonds = Patterns.diamonds(columns: 3, rows: 3, diamond_scale: 0.75, hollow_stroke: 3.0)
    diamonds.to_svg.includes?(%(stroke-width="3")).should be_true

    crosses = Patterns.crosses(columns: 2, rows: 2, arm_length: 24.0, arm_thickness: 6.0, diagonal_x: true)
    crosses.to_svg.includes?("rotate(45,").should be_true

    stars = Patterns.stars(columns: 2, rows: 2, points: 5, outer_radius: 20.0, inner_radius: 8.0)
    stars.to_svg.includes?(%(<polygon points=)).should be_true

    bricks = Patterns.bricks(columns: 2, rows: 4, mortar_gap: 4.0, corner_radius: 2.0)
    bricks.to_svg.includes?(%(<rect )).should be_true

    houndstooth = Patterns.houndstooth(subdivisions: 2, tooth_slant: 0.5)
    houndstooth.to_svg.includes?(%(<polygon points=)).should be_true

    halftone = Patterns.halftone(columns: 6, rows: 6, min_radius: 2.0, max_radius: 8.0, radial_falloff: true)
    halftone.to_svg.includes?(%(<circle )).should be_true

    CustomPatternGenerator::PatternKind.each do |kind|
      custom = Patterns.custom(kind: kind, columns: 2, rows: 2, primary_size: 16.0, secondary_size: 4.0)
      svg = custom.to_svg
      svg.starts_with?("<svg ").should be_true
      svg.ends_with?("</svg>\n").should be_true
    end
  end
end
