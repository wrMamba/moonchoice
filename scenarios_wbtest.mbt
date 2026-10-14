///|
test "scenario grid records changing winners without probabilistic claims" {
  let m = sample()
  let grid = weight_grid([1.0, 1.0], 0, [0.0, 0.5, 1.0])
  let r = weight_scenarios(m, grid, Additive(MinMax))
  assert_eq(r.winner_counts, [0, 2, 2])
  assert_eq(r.universally_best, [])
  for i in 0..<3 {
    assert_eq(r.rank_counts[i].fold(init=0, (a, b) => a + b), 3)
  }
  assert_eq(weight_grid([1.0, 0.0, 0.0], 0, [0.5]), [[0.5, 0.25, 0.25]])
}
