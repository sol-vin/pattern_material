require "lapis"
require "./pattern_material"

# In non-release builds, load in-editor test suites and documentation so they
# register with Lapis::Test and appear in the Crystal Editor Hub.
{% unless flag?(:release) %}
  require "../spec/editor/**"
  require "./docs"
{% end %}
