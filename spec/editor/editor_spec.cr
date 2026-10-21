require "spec"
require "lapis"

include Lapis::Test

# =============================================================================
# Pattern Material In-Editor Test Suite (spec/editor/editor_spec.cr)
# =============================================================================
# These tests are registered into Lapis::Test::Registry and executed live
# inside the Godot Editor through the Crystal Hub dock (Unit Test Runner tab).

test_suite "PatternMaterialNodes" do
  test "PatternMaterialPlugin is registered as a tool EditorPlugin" do
    entry = Godot::ClassRegistry.find("PatternMaterialPlugin")
    assert_not_nil entry, "Expected PatternMaterialPlugin to be registered"
    assert_eq entry.not_nil!.parent_name, "EditorPlugin"
    assert_true entry.not_nil!.is_tool, "PatternMaterialPlugin must have is_tool == true"
  end

  test "PatternGeneratorTool is registered as a tool Node" do
    entry = Godot::ClassRegistry.find("PatternGeneratorTool")
    assert_not_nil entry, "Expected PatternGeneratorTool to be registered"
    assert_eq entry.not_nil!.parent_name, "Node"
    assert_true entry.not_nil!.is_tool, "PatternGeneratorTool must have is_tool == true"
  end

  test "All 14 procedural PatternGenerator classes are registered" do
    [
      "PolkaDotPattern", "StripePattern", "CheckerPattern", "ZigZagPattern",
      "WavePattern", "RingPattern", "HexagonPattern", "DiamondPattern",
      "CrossPattern", "StarPattern", "BrickPattern", "HoundstoothPattern",
      "HalftonePattern", "CustomPatternGenerator",
    ].each do |name|
      entry = Godot::ClassRegistry.find(name)
      assert_not_nil entry, "Expected #{name} to be registered in ClassRegistry"
    end
  end
end

describe "Addon In-Editor Test Suite" do
  it "registers addon in-editor tests with Lapis::Test" do
    tests = Registry.all_tests
    tests.should_not be_empty
  end
end
