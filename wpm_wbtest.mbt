///|
test "log product is unit invariant and rejects zero" {
  let a = decision_matrix(["A", "B"], ["x", "y"], [Benefit, Cost], [
    [2.0, 2.0],
    [4.0, 4.0],
  ])
  let r = weighted_product(a, [1.0, 1.0])
  assert_true((r.ranking.scores[0] - r.ranking.scores[1]).abs() < 1.0e-14)
  let z = decision_matrix(["A"], ["x"], [Benefit], [[0.0]])
  try weighted_product(z, [1.0]) catch {
    _ => ()
  } noraise {
    _ => fail("expected rejection")
  }
}
