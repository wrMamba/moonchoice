///|
test "objective weights expose lack of information" {
  let m = decision_matrix(["A", "B"], ["x", "y"], [Benefit, Cost], [
    [2.0, 2.0],
    [2.0, 2.0],
  ])
  for estimate in [entropy_weights(m), deviation_weights(m), critic_weights(m)] {
    assert_true(estimate.uniform_fallback)
    assert_eq(estimate.weights, [0.5, 0.5])
  }
  assert_true(!entropy_weights(sample()).uniform_fallback)
  assert_true((sum(deviation_weights(sample()).weights) - 1.0).abs() < 1.0e-14)
}
