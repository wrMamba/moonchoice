///|
fn main raise {
  let m = @choice.decision_matrix(
    ["edge", "balanced", "large"],
    ["latency", "throughput", "memory"],
    [@choice.Cost, @choice.Benefit, @choice.Cost],
    [[12.0, 100.0, 2.0], [8.0, 160.0, 4.0], [10.0, 200.0, 8.0]],
  )
  let w = [0.5, 0.3, 0.2]
  let preferences = [
    @choice.Linear(1.0, 5.0),
    @choice.VShape(80.0),
    @choice.UShape(1.0),
  ]
  let flows = @choice.promethee(m, w, preferences)
  assert_eq(flows.ranking.winners(), ["balanced"])
  let explanation = @choice.explain_pair(m, w, preferences, 1, 0)
  assert_true(explanation.net_preference > 0.0)
  let comparison = @choice.compare_methods(m, w, [
    @choice.IdealDistance(@choice.MinMax),
    @choice.Outranking(preferences),
  ])
  assert_eq(comparison.rankings.length(), 2)
  println(@choice.ranking_json(flows.ranking).stringify())
}
