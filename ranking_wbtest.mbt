///|
test "ties use an anchor rather than nontransitive comparator" {
  let r = rank_scores(
    ["A", "B", "C"],
    [0.0, 0.00008, 0.00016],
    tolerance=0.0001,
  )
  assert_eq(r.order, [2, 1, 0])
  assert_eq(r.ranks, [3, 1, 1])
  assert_eq(r.winners(), ["C", "B"])
  assert_eq(rank_scores(["A", "B"], [1.0, 1.0]).order, [0, 1])
}
