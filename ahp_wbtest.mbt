///|
test "consistent AHP recovers ratio weights with small eigen residual" {
  let r = ahp([[1.0, 2.0, 4.0], [0.5, 1.0, 2.0], [0.25, 0.5, 1.0]])
  assert_true((r.weights[0] - 4.0 / 7.0).abs() < 1.0e-12)
  assert_true(r.consistency_ratio < 1.0e-12)
  assert_true(r.residual < 1.0e-12)
  let bad = ahp([[1.0, 9.0, 0.2], [1.0 / 9.0, 1.0, 7.0], [5.0, 1.0 / 7.0, 1.0]])
  assert_true(bad.consistency_ratio > 0.1)
  assert_eq(bad.worst_triad, [0, 1, 2])
}
