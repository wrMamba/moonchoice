///|
test "VIKOR supports degenerate criteria and singleton compromise" {
  let m = decision_matrix(["A", "B"], ["x", "y"], [Benefit, Cost], [
    [1.0, 2.0],
    [3.0, 2.0],
  ])
  let r = vikor(m, [1.0, 1.0])
  assert_eq(r.ranking.order, [1, 0])
  assert_eq(r.compromise, ["B"])
  assert_eq(r.criterion_regrets[0][1], 0.0)
  let one = decision_matrix(["A"], ["x"], [Benefit], [[1.0]])
  assert_eq(vikor(one, [1.0]).compromise, ["A"])
}
