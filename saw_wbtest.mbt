///|
test "SAW contributions reconstruct each score" {
  let r = saw(sample(), [1.0, 1.0])
  assert_eq(r.ranking.winners(), ["B", "C"])
  for i in 0..<3 {
    assert_eq(sum(r.contributions[i]), r.ranking.scores[i])
  }
}
