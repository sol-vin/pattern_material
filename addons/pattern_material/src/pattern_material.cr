require "lapis"
require "./resources/palette"
require "./resources/spritesheet_atlas"
require "./resources/spritesheets"
require "./generators/pattern_generator"
require "./generators/generators"
require "./resources/patterns"
require "./resources/universal_material"
require "./tools/svg_spritesheet_builder"
require "./tools/faces_spritesheet_builder"
require "./tools/fontawesome_category_importer"
require "./tools/pattern_generator_node"

include Godot

module PatternMaterialAddon
  VERSION = "0.1.0"
end

# Godot EditorPlugin entry point for the `pattern_material` addon.
@[Tool]
node PatternMaterialPlugin < EditorPlugin do
  SHADER_PATH  = UniversalMaterial::SHADER_PATH
  PATTERNS_DIR = Patterns::SOURCE_DIR

  def _enter_tree : Void
    Godot.print("==================================================================")
    Godot.print("  [LapisAddon] [PatternMaterialPlugin] Plugin activated in Godot Editor!")
    Godot.print("  [CRYSTAL_ADDON_VERIFIED_SUCCESS_8A3F1E] Pattern Material GDExtension plugin running in editor!")
    Godot.print("  [PatternMaterial] Shader: #{SHADER_PATH} | Patterns: #{Patterns.count} | Generators: 14")
    Godot.print("==================================================================")
  end

  def _exit_tree : Void
    Godot.print("  [LapisAddon] [PatternMaterialPlugin] Plugin deactivated in Godot Editor.")
  end
end
