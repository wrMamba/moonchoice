///|
fn close_arrays(
  a : Array[Double],
  b : Array[Double],
  eps~ : Double = 1.0e-10,
) -> Unit raise {
  assert_eq(a.length(), b.length())
  for i in 0..<a.length() {
    assert_true((a[i] - b[i]).abs() <= eps)
  }
}

///|
test "minmax models invariant to positive affine unit conversions" {
  for seed in 1..<21 {
    let cells = [
      for i in 0..<7 => {
        [
          for j in 0..<3 => {
            ((i * i * 7 + j * 19 + seed * (i + 3)) % 97 + 1).to_double()
          }
        ]
      }
    ]
    let m = decision_matrix(
      ["a", "b", "c", "d", "e", "f", "g"],
      ["x", "y", "z"],
      [Benefit, Cost, Benefit],
      cells,
    )
    let converted = m.convert_units([2.0, 100.0, 0.5], [-10.0, 7.0, 19.0])
    let w = [0.2, 0.3, 0.5]
    for algorithm in [Additive(MinMax), IdealDistance(MinMax), Compromise(0.5)] {
      close_arrays(
        evaluate(m, w, algorithm).scores,
        evaluate(converted, w, algorithm).scores,
      )
    }
  }
}

///|
test "permutation equivariance aligns rankings by label" {
  let m = sample()
  let permuted = m.select_alternatives([2, 0, 1])
  for
    algorithm in [
      Additive(MinMax),
      IdealDistance(Vector),
      Product,
      Compromise(0.7),
      Outranking([Usual, Usual]),
    ] {
    let a = evaluate(m, [0.6, 0.4], algorithm)
    let b = evaluate(permuted, [0.6, 0.4], algorithm)
    close_arrays(b.scores, [a.scores[2], a.scores[0], a.scores[1]])
    let agreement = rank_agreement(a, b)
    assert_true(agreement.spearman is Some(x) && (x - 1.0).abs() < 1.0e-12)
  }
}

///|
test "all ranking engines agree on strict dominance chain" {
  let m = decision_matrix(
    ["best", "middle", "worst"],
    ["quality", "latency"],
    [Benefit, Cost],
    [[9.0, 1.0], [5.0, 5.0], [1.0, 9.0]],
  )
  for
    algorithm in [
      Additive(MinMax),
      IdealDistance(MinMax),
      Product,
      Compromise(0.5),
      Outranking([Usual, Usual]),
    ] {
    assert_eq(evaluate(m, [1.0, 1.0], algorithm).order, [0, 1, 2])
  }
  assert_eq(pareto_fronts(m).fronts, [["best"], ["middle"], ["worst"]])
}

///|
test "constant singleton and zero-weight criteria have explicit results" {
  let m = decision_matrix(["a", "b"], ["x", "y"], [Benefit, Cost], [
    [7.0, 3.0],
    [7.0, 3.0],
  ])
  for
    algorithm in [
      Additive(MinMax),
      IdealDistance(Vector),
      Product,
      Compromise(0.5),
      Outranking([Usual, Usual]),
    ] {
    assert_eq(evaluate(m, [1.0, 0.0], algorithm).ranks, [1, 1])
  }
  close_arrays(topsis(m, [1.0, 1.0]).ranking.scores, [0.5, 0.5])
  for estimate in [entropy_weights(m), deviation_weights(m), critic_weights(m)] {
    assert_true(estimate.uniform_fallback)
    close_arrays(estimate.weights, [0.5, 0.5])
  }
  let single = m.select_alternatives([0])
  assert_eq(promethee(single, [1.0, 1.0], [Usual, Usual]).ranking.scores, [0.0])
  assert_eq(vikor(single, [1.0, 1.0]).compromise, ["a"])
}

///|
test "weight scaling and near-extreme finite values stay bounded" {
  close_arrays(
    normalize_weights([1.0e100, 2.0e99]),
    normalize_weights([10.0, 2.0]),
  )
  let m = decision_matrix(["a", "b"], ["x"], [Benefit], [[-1.0e100], [1.0e100]])
  close_arrays(saw(m, [1.0]).ranking.scores, [0.0, 1.0])
  close_arrays(topsis(m, [1.0]).ranking.scores, [0.0, 1.0])
  let tiny = decision_matrix(["a", "b"], ["x"], [Benefit], [
    [1.0e-200],
    [2.0e-200],
  ])
  close_arrays(topsis(tiny, [1.0]).ranking.scores, [0.0, 1.0])
  assert_true(preference_degree(Gaussian(1.0e-100), 1.0e100) == 1.0)
}

///|
test "invalid numeric shape weight and mutation inputs are rejected" {
  let m = sample()
  for w in [[], [0.0, 0.0], [-1.0, 2.0], [1.0], [1.0e101, 2.0]] {
    try saw(m, w) catch {
      _ => ()
    } noraise {
      _ => fail("invalid weights accepted")
    }
  }
  for value in [1.0e101, 0.0 / 0.0, 1.0 / 0.0] {
    try decision_matrix(["a"], ["x"], [Benefit], [[value]]) catch {
      _ => ()
    } noraise {
      _ => fail("nonfinite value accepted")
    }
  }
  let r = saw(m, [1.0, 1.0]).ranking
  r.ranks[0] = 999
  try r.winners() catch {
    _ => ()
  } noraise {
    _ => fail("forged ranking accepted")
  }
  try m.select_alternatives([0, 0]) catch {
    _ => ()
  } noraise {
    _ => fail("duplicate selection accepted")
  }
}

///|
test "budget failures occur before large scenario computations" {
  let m = decision_matrix(
    [
      for i in 0..<256 => i.to_string()
    ],
    [
      for j in 0..<32 => j.to_string()
    ],
    Array::make(32, Benefit),
    [
      for _ in 0..<256 => Array::make(32, 1.0)
    ],
  )
  try
    weight_scenarios(
      m,
      [
        Array::make(32, 1.0),
        Array::make(32, 1.0),
        Array::make(32, 1.0),
        Array::make(32, 1.0),
        Array::make(32, 1.0),
        Array::make(32, 1.0),
        Array::make(32, 1.0),
        Array::make(32, 1.0),
        Array::make(32, 1.0),
      ],
      Additive(MinMax),
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("scenario work limit not enforced")
  }
  try parse_document(String::make(1048577, ' ')) catch {
    _ => ()
  } noraise {
    _ => fail("document budget missing")
  }
}

///|
test "preference thresholds cover boundaries for six families" {
  close_arrays(
    [
      preference_degree(Usual, 0.0),
      preference_degree(UShape(2.0), 2.0),
      preference_degree(VShape(4.0), 2.0),
      preference_degree(Level(1.0, 3.0), 3.0),
      preference_degree(Linear(1.0, 3.0), 2.0),
    ],
    [0.0, 0.0, 0.5, 0.5, 0.5],
  )
  for
    pref in [
      UShape(-1.0),
      VShape(0.0),
      Level(2.0, 1.0),
      Linear(1.0, 1.0),
      Gaussian(0.0),
    ] {
    try preference_degree(pref, 1.0) catch {
      _ => ()
    } noraise {
      _ => fail("invalid preference accepted")
    }
  }
}

///|
test "AHP validation rejects nonreciprocal and exhausted iterations" {
  try ahp([[1.0, 2.0], [2.0, 1.0]]) catch {
    _ => ()
  } noraise {
    _ => fail("nonreciprocal AHP accepted")
  }
  try
    ahp(
      [[1.0, 3.0, 7.0], [1.0 / 3.0, 1.0, 2.0], [1.0 / 7.0, 0.5, 1.0]],
      max_iterations=1,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("AHP iteration budget missing")
  }
  assert_eq(ahp([[1.0]]).weights, [1.0])
}

///|
test "analytic crossing agrees with grid and excludes singleton sweep" {
  let m = sample()
  let crossing = additive_break_even(m, [1.0, 1.0], 0, 1, 2)
  assert_true(crossing.crossing is Some(x) && (x - 0.5).abs() < 1.0e-12)
  let r = weight_scenarios(
    m,
    weight_grid([1.0, 1.0], 0, [0.49, 0.5, 0.51]),
    Additive(MinMax),
  )
  assert_eq(r.rankings[0].winners(), ["C"])
  assert_eq(r.rankings[1].winners(), ["B", "C"])
  assert_eq(r.rankings[2].winners(), ["B"])
  let single = m.select_criteria([0])
  try additive_break_even(single, [1.0], 0, 0, 1) catch {
    _ => ()
  } noraise {
    _ => fail("singleton sweep accepted")
  }
}
