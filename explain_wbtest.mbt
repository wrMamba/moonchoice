///|
test "pairwise explanation reconstructs PROMETHEE and break-even crossing" {
  let m = sample()
  let e = explain_pair(m, [1.0, 1.0], [Usual, Usual], 1, 2)
  assert_eq(e.aggregate_left, 0.5)
  assert_eq(e.aggregate_right, 0.5)
  assert_true(!e.left_dominates)
  let b = additive_break_even(m, [1.0, 1.0], 0, 1, 2)
  assert_eq(b.crossing, Some(0.5))
  let r = saw(m, [0.5, 0.5])
  assert_true((r.ranking.scores[1] - r.ranking.scores[2]).abs() < 1.0e-14)
}
