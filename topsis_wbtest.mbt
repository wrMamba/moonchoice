///|
test "TOPSIS identical rows return neutral ties" {
  let m = decision_matrix(["A", "B"], ["x"], [Cost], [[2.0], [2.0]])
  assert_eq(topsis(m, [1.0]).ranking.scores, [0.5, 0.5])
  let one = decision_matrix(["A", "B"], ["x"], [Benefit], [[1.0], [2.0]])
  assert_eq(topsis(one, [1.0]).ranking.scores, [0.0, 1.0])
}
