///|
test "compensated sum and numeric input safety" {
  assert_eq(sum([1.0e16, 1.0, -1.0e16]), 1.0)
  assert_true(!finite(0.0 / 0.0))
  try input_number(1.0e101) catch {
    _ => ()
  } noraise {
    _ => fail("expected rejection")
  }
  try valid_tolerance(-1.0) catch {
    _ => ()
  } noraise {
    _ => fail("expected rejection")
  }
}
