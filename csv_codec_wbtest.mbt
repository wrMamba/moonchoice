///|
test "CSV preserves punctuation Unicode quotes and embedded lines" {
  let m = decision_matrix(["A,一", "B\"\n二"], ["speed"], [Benefit], [[1.0], [2.0]])
  let again = decode_csv(encode_csv(m))
  assert_eq(again.alternatives(), m.alternatives())
  assert_eq(again.values(), m.values())
  for bad in ["alternative,x\ndirection,cost\na,1,2", "alternative,x\ndirection,cost\na,NaN", "alternative,x\ndirection,cost\n\"a\"x,1", "alternative,x\ndirection,cost\n\"a,1"] {
    try decode_csv(bad) catch { _ => () } noraise { _ => fail("bad CSV accepted") }
  }
}
