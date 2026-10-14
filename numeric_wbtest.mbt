///|
test "compensated sum and numeric input safety" {
  assert_eq(sum([1.0e16, 1.0, -1.0e16]), 1.0)
  assert_true(!finite(0.0 / 0.0))
  assert_true((try? input_number(1.0e101)) is Err(_))
  assert_true((try? valid_tolerance(-1.0)) is Err(_))
}
