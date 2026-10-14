///|
fn main raise {
  let csv = "alternative,throughput,cost\ndirection,benefit,cost\nA,7,8\nB,9,10\nC,6,5\n"
  let m = @choice.decode_csv(csv)
  let result = @choice.saw(m, [0.5, 0.5])
  assert_eq(result.ranking.winners(), ["B", "C"])
  assert_eq(
    @choice.decode_matrix(@choice.encode_matrix(m)).values(),
    m.values(),
  )
  assert_true((result.contributions[0][0] - 1.0 / 6.0).abs() < 1.0e-12)
  let report = @choice.decision_report(
    m,
    [0.5, 0.5],
    @choice.Additive(@choice.MinMax),
  )
  println(@choice.report_json(report).stringify())
}
