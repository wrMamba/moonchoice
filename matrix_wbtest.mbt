///|
fn sample() -> DecisionMatrix raise ChoiceError {
  decision_matrix(["A", "B", "C"], ["quality", "cost"], [Benefit, Cost], [[7.0, 8.0], [9.0, 10.0], [6.0, 5.0]])
}

///|
test "matrix copies input and output without aliasing" {
  let rows = [[1.0], [2.0]]
  let m = decision_matrix(["A", "B"], ["x"], [Benefit], rows)
  rows[0][0] = 5.0
  let output = m.values()
  output[0][0] = 8.0
  assert_eq(m.cell(0, 0), 1.0)
  assert_true((try? m.cell(-1, 0)) is Err(_))
  assert_true((try? decision_matrix(["A", "A"], ["x"], [Benefit], [[1.0], [2.0]])) is Err(_))
}
