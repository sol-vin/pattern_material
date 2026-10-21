# =============================================================================
# Pattern Material Comparison Benchmark (Crystal)
# =============================================================================

require "../src/pattern_material"

count = (ARGV[0]? || "2000").to_i

Lapis::Benchmark.group "ProceduralPatternGenerators" do |g|
  g.description("Comparing procedural SVG synthesis speed across geometric complexity tiers")
  g.category(:engine)
  g.kind(:runtime)
  g.charts(:bar, :speedup, :ratio, :log)

  g.subgroup "Generators" do |sg|
    sg.benchmark "CheckerPattern" do |_iter|
      gen = Patterns.checkers(columns: 4, rows: 4)
      bytes = 0
      count.times { bytes += gen.to_svg.bytesize }
      Lapis::Benchmark.report_metric("bytes", bytes.to_f64)
    end

    sg.benchmark "PolkaDotPattern" do |_iter|
      gen = Patterns.polka_dots(dot_radius: 14.0, columns: 3, rows: 3)
      bytes = 0
      count.times { bytes += gen.to_svg.bytesize }
      Lapis::Benchmark.report_metric("bytes", bytes.to_f64)
    end

    sg.benchmark "HoundstoothPattern" do |_iter|
      gen = Patterns.houndstooth(subdivisions: 2, tooth_slant: 0.5)
      bytes = 0
      count.times { bytes += gen.to_svg.bytesize }
      Lapis::Benchmark.report_metric("bytes", bytes.to_f64)
    end
  end

  g.baseline("CheckerPattern")
end

results = Lapis::Benchmark.run_all_groups(iterations: 3)
results.each do |grp|
  puts "Group: #{grp.group_name} [#{grp.category.display_name}] Kind: #{grp.kind} Charts: #{grp.chart_types.join(",")} (Baseline: #{grp.baseline_name})"
  grp.targets.each do |t|
    puts "  %-24s %6.2f ms" % [t.name, t.median_ms]
  end
  if first = grp.targets.first?
    puts "ELAPSED_MS: #{first.median_ms.round(2)}"
  end
end
