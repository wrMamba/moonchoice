///|
test "six preference functions enforce threshold endpoints" {
  assert_eq(preference_degree(Usual, 0.0), 0.0)
  assert_eq(preference_degree(UShape(2.0), 2.0), 0.0)
  assert_eq(preference_degree(VShape(2.0), 1.0), 0.5)
  assert_eq(preference_degree(Level(1.0, 3.0), 3.0), 0.5)
  assert_eq(preference_degree(Linear(1.0, 3.0), 2.0), 0.5)
  assert_true((preference_degree(Gaussian(1.0), 1.0) - 0.3934693402873666).abs() < 1.0e-14)
  try preference_degree(Linear(2.0, 2.0), 1.0) catch { _ => () } noraise { _ => fail("expected rejection") }
}
