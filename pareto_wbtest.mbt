///|
test "Pareto layers preserve incomparability and duplicate alternatives" {
  let m = decision_matrix(
    ["A", "B", "C", "D"],
    ["x", "y"],
    [Benefit, Benefit],
    [[3.0, 1.0], [1.0, 3.0], [1.0, 1.0], [1.0, 1.0]],
  )
  let r = pareto_fronts(m)
  assert_eq(r.fronts, [["A", "B"], ["C", "D"]])
  assert_eq(r.dominated_by[2], [0, 1])
}
