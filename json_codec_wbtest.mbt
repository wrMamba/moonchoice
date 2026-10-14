///|
test "versioned matrix JSON roundtrip and strict unknown fields" {
  let m = sample()
  let restored = decode_matrix(encode_matrix(m))
  assert_eq(restored.values(), m.values())
  assert_eq(restored.criterion_directions(), m.criterion_directions())
  let bad = Json::object({"schema": Json::string("moonchoice.matrix/1"), "extra": Json::null()})
  try matrix_from_json(bad) catch { _ => () } noraise { _ => fail("unknown fields accepted") }
  try parse_document("[[[[[[[[[0]]]]]]]]]") catch { _ => () } noraise { _ => fail("depth accepted") }
  assert_true(ranking_json(saw(m, [1.0, 1.0]).ranking) is Object(_))
}
