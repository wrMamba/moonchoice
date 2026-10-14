///|
fn main raise {
  let m = @choice.decision_matrix(
    ["A", "B", "C"],
    ["quality", "cost"],
    [@choice.Benefit, @choice.Cost],
    [[7.0, 8.0], [9.0, 10.0], [6.0, 5.0]],
  )
  let grid = @choice.weight_grid([0.5, 0.5], 0, [0.0, 0.5, 1.0])
  let report = @choice.weight_scenarios(
    m,
    grid,
    @choice.Additive(@choice.MinMax),
  )
  assert_eq(report.winner_counts, [0, 2, 2])
  assert_eq(report.universally_best, [])
  let crossing = @choice.additive_break_even(m, [0.5, 0.5], 0, 1, 2)
  assert_true(crossing.crossing is Some(x) && (x - 0.5).abs() < 1.0e-12)
  let request = Json::object({
    "schema": Json("moonchoice.request/1"),
    "operation": Json("scenarios"),
    "matrix": m.to_json(),
    "scenarios": Json(grid),
    "algorithm": Json::object({
      "kind": Json("saw"),
      "normalization": Json("minmax"),
    }),
  })
  let response = @choice.parse_document(@choice.dispatch(request.stringify()))
  assert_true(response is Object(fields) && fields.get("ok") is Some(True))
  println(@choice.dispatch(request.stringify()))
}
