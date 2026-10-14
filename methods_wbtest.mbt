///|
test "algorithm comparison keeps score orientation explicit" {
  let r = compare_methods(sample(), [1.0, 1.0], [Additive(MinMax), IdealDistance(MinMax), Compromise(0.5)])
  assert_true(r.rankings[0].higher_is_better)
  assert_true(!r.rankings[2].higher_is_better)
  assert_eq(r.agreements.length(), 3)
  assert_eq(r.agreements[0][0].spearman, Some(1.0))
}
