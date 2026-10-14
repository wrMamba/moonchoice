///|
pub(all) struct AhpResult {
  weights : Array[Double]
  lambda_max : Double
  consistency_index : Double
  consistency_ratio : Double
  residual : Double
  iterations : Int32
  worst_triad : Array[Int32]
  worst_log_inconsistency : Double
} derive(@debug.Debug)

///|
/// Reciprocal positive matrices of size 1..15; bounded power iteration.
pub fn ahp(
  comparisons : Array[Array[Double]],
  tolerance~ : Double = 1.0e-10,
  max_iterations~ : Int32 = 2048,
) -> AhpResult raise ChoiceError {
  let n = comparisons.length()
  if n == 0 || n > 15 {
    raise Budget("AHP matrix size must be 1..15")
  }
  if !finite(tolerance) || tolerance < 1.0e-14 || tolerance > 1.0e-4 {
    raise Invalid("AHP tolerance must be 1e-14..1e-4")
  }
  if max_iterations < 1 || max_iterations > 4096 {
    raise Budget("AHP iteration budget must be 1..4096")
  }
  for row in comparisons {
    if row.length() != n {
      raise Invalid("AHP matrix must be square")
    }
    for x in row {
      if !finite(x) || x < 1.0e-9 || x > 1.0e9 {
        raise Invalid("AHP entries must be in 1e-9..1e9")
      }
    }
  }
  for i in 0..<n {
    if (comparisons[i][i] - 1.0).abs() > 1.0e-8 {
      raise Invalid("AHP diagonal must be one")
    }
    for j in 0..<n {
      if (comparisons[i][j] * comparisons[j][i] - 1.0).abs() > 1.0e-8 {
        raise Invalid("AHP entries must be reciprocal")
      }
    }
  }
  let mut weights = Array::make(n, 1.0 / n.to_double())
  let mut iterations = 0
  let mut converged = false
  for step in 1..<(max_iterations + 1) {
    let next = [
      for i in 0..<n => {
        sum([ for j in 0..<n => comparisons[i][j] * weights[j] ])
      }
    ]
    let total = sum(next)
    for i in 0..<n {
      next[i] /= total
    }
    let change = maximum([ for i in 0..<n => (next[i] - weights[i]).abs() ])
    weights = next
    iterations = step
    if change <= tolerance {
      converged = true
      break
    }
  }
  if !converged {
    raise Numerical("AHP did not converge within the iteration budget")
  }
  let product = [
    for i in 0..<n => sum([ for j in 0..<n => comparisons[i][j] * weights[j] ])
  ]
  let lambda_max = sum([ for i in 0..<n => product[i] / weights[i] ]) /
    n.to_double()
  let residual = maximum(
    [
      for i in 0..<n => (product[i] - lambda_max * weights[i]).abs()
    ],
  )
  let raw_index = if n <= 1 {
    0.0
  } else {
    (lambda_max - n.to_double()) / (n - 1).to_double()
  }
  let consistency_index = if raw_index < 0.0 { 0.0 } else { raw_index }
  let ri = [
    0.0, 0.0, 0.58, 0.90, 1.12, 1.24, 1.32, 1.41, 1.45, 1.49, 1.51, 1.48, 1.56, 1.57,
    1.59,
  ]
  let consistency_ratio = if n <= 2 {
    0.0
  } else {
    consistency_index / ri[n - 1]
  }
  let mut worst_triad : Array[Int32] = []
  let mut worst_log_inconsistency = 0.0
  for i in 0..<n {
    for j in (i + 1)..<n {
      for k in (j + 1)..<n {
        let error = (@math.ln(comparisons[i][j]) +
        @math.ln(comparisons[j][k]) -
        @math.ln(comparisons[i][k])).abs()
        if error > worst_log_inconsistency {
          worst_log_inconsistency = error
          worst_triad = [i, j, k]
        }
      }
    }
  }
  {
    weights,
    lambda_max,
    consistency_index,
    consistency_ratio,
    residual,
    iterations,
    worst_triad,
    worst_log_inconsistency,
  }
}

///|
pub extend AhpResult with @debug.Debug::{to_repr}
