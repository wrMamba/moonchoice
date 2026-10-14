///|
test "unit conversion preserves minmax ranking and removal preserves labels" {
  let m = sample()
  let converted = m.convert_units([10.0, 2.0], [3.0, -1.0])
  assert_eq(saw(m, [1.0, 1.0]).ranking.order, saw(converted, [1.0, 1.0]).ranking.order)
  let r = removal_analysis(m, [1.0, 1.0], IdealDistance(MinMax), 0)
  assert_eq(r.remaining.labels, ["B", "C"])
  assert_eq(m.select_criteria([1]).criterion_names(), ["cost"])
}
