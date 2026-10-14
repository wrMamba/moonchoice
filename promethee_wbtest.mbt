///|
test "PROMETHEE flow is antisymmetric and self preference is zero" {
  let r = promethee(sample(), [1.0, 1.0], [Usual, Usual])
  assert_true(sum(r.ranking.scores).abs() < 1.0e-14)
  for i in 0..<3 {
    assert_eq(r.preference_matrix[i][i], 0.0)
    assert_true((r.positive_flow[i] - r.negative_flow[i] - r.ranking.scores[i]).abs() < 1.0e-14)
  }
}
