///|
test "rank agreement aligns labels and handles ties and reversal" {
  let a = rank_scores(["A", "B", "C"], [3.0, 2.0, 1.0])
  let b = rank_scores(["C", "A", "B"], [3.0, 1.0, 2.0])
  let r = rank_agreement(a, b)
  assert_eq(r.spearman, Some(-1.0))
  assert_eq(r.kendall_tau_b, Some(-1.0))
  assert_eq(r.discordant_pairs, 3)
  let tied = rank_scores(["A", "B", "C"], [1.0, 1.0, 1.0])
  assert_eq(rank_agreement(tied, tied).spearman, None)
}
