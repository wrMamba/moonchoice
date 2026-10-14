///|
test "criterion diagnostics and leave-one-out recomputation" {
  let m = sample()
  let profiles = criterion_profiles(m, [1.0, 1.0])
  assert_eq(profiles[0].distinct_values, 3)
  assert_true((profiles[1].mean - 23.0 / 3.0).abs() < 1.0e-12)
  let sensitivity = criterion_sensitivity(m, [1.0, 1.0], Additive(MinMax))
  assert_eq(sensitivity.removals.length(), 2)
  assert_eq(sensitivity.removals[0].ranking.winners(), ["C"])
  assert_eq(sensitivity.removals[1].ranking.winners(), ["B"])
  let only = criterion_sensitivity(m, [1.0, 0.0], Additive(MinMax))
  assert_eq(only.skipped_zero_weight_remainders, ["quality"])
  assert_true(report_json(decision_report(m, [1.0, 1.0], IdealDistance(MinMax))) is Object(_))
}
