# =============================================================================
# Pattern Material Addon Benchmark (Crystal)
# =============================================================================

require "../src/pattern_material"

count = (ARGV[0]? || "2000").to_i

Lapis::Benchmark.register("PatternGeneratorSvgSynthesis", category: Lapis::Benchmark::Category::Engine, description: "Procedural SVG synthesis across PolkaDotPattern, StripePattern, and HoundstoothPattern") do |iter|
  dots = Patterns.polka_dots(dot_radius: 14.0, columns: 3, rows: 3)
  stripes = Patterns.stripes(stripe_count: 6, duty_cycle: 0.4, angle_degrees: 45.0)
  houndstooth = Patterns.houndstooth(subdivisions: 2, tooth_slant: 0.5)

  start_time = Time.instant
  total_bytes = 0
  count.times do
    total_bytes += dots.to_svg.bytesize
    total_bytes += stripes.to_svg.bytesize
    total_bytes += houndstooth.to_svg.bytesize
  end
  elapsed = (Time.instant - start_time).total_milliseconds

  Lapis::Benchmark.report_elapsed_ms(elapsed)
  Lapis::Benchmark.report_metric("total_svg_bytes", total_bytes.to_f64)

  if iter == 0
    puts "PatternGeneratorSvgSynthesis #{count} iterations: #{total_bytes} bytes"
    puts "METRIC: total_svg_bytes=#{total_bytes}"
    puts "ELAPSED_MS: #{elapsed.round(2)}"
  end
end

results = Lapis::Benchmark.run_all(iterations: 3)
if res = results.first?
  puts "Result: #{res.name} median: #{res.median_ms.round(2)} ms"
end
