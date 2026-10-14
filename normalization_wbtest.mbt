///|
test "normalization handles directions constants and large magnitudes" {
  let m = sample()
  let x = m.normalize(MinMax)
  assert_eq(x[1][0], 1.0)
  assert_eq(x[2][1], 1.0)
  assert_eq(normalize_weights([2.0, 2.0]), [0.5, 0.5])
  try normalize_weights([0.0, 0.0]) catch {
    _ => ()
  } noraise {
    _ => fail("expected rejection")
  }
  let huge = decision_matrix(["A", "B"], ["x"], [Cost], [[1.0e100], [-1.0e100]])
  let y = huge.normalize(Vector)
  assert_true((y[0][0] + y[1][0]).abs() < 1.0e-14)
}
