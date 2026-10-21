# PATTERN MATERIAL CHANGELOG
## [0.1.1] - 2026-10-21
### ✨ Features & Improvements
- ✦ initial release of pattern_material addon for Godot 4 and Lapis (`99bb486`)

---
## [0.1.0] - 2026-10-21
> Initial release of the Pattern Material addon for Godot 4.8+ and Lapis.
### ✨ Features & Improvements
- ✦ Added `pattern_replace.gdshader` with duotone color replacement, 2D/3D surface projection (`WorldTriplanar`, `MeshUV`, `Cylindrical`), boiling outlines, bevel/rim lighting, Fresnel glow, Bayer dithering, dissolve, retro CRT glitch/scanlines, screen-space backdrop FX, and vertex motion. (`initial`)
- ✦ Added `PolkaDotPattern`, `StripePattern`, `CheckerPattern`, `ZigZagPattern`, `WavePattern`, `RingPattern`, `HexagonPattern`, `DiamondPattern`, `CrossPattern`, `StarPattern`, `BrickPattern`, `HoundstoothPattern`, `HalftonePattern`, and `CustomPatternGenerator` with Inspector exports and `Patterns` factory methods. (`generators`)
- ✦ Bundled 88 Hero Patterns SVGs (`Patterns`), the 32-color `Palette` loader, `SpritesheetAtlas`, `Faces`, `Glyphs`, `SvgSpritesheetBuilder`, `FacesSpritesheetBuilder`, `FontAwesomeCategories`, `PatternGeneratorTool`, and 4 `.tres` material presets. (`assets`)

### 📚 Documentation
- 📖 Added structured Jasper documentation (`PatternMaterialAddon::Docs`), headless and in-editor spec suites, SVG synthesis benchmarks, and GitHub Actions CI/Release pipelines supporting `lapis install addon github:sol-vin/pattern_material`. (`docs`)

