///|
pub(all) struct PrometheeResult {
  ranking : Ranking
  preference_matrix : Array[Array[Double]]
  positive_flow : Array[Double]
  negative_flow : Array[Double]
} derive(Debug)

///|
fn preference_specs(m : DecisionMatrix, specs : Array[Preference]) -> Unit raise ChoiceError {
  if specs.length() != m.criteria.length() {
    raise Invalid("preference specification count mismatch")
  }
  for spec in specs { valid_preference(spec) }
}

///|
/// Thresholds are in raw criterion units, not normalized units.
pub fn promethee(m : DecisionMatrix, weights : Array[Double], preferences : Array[Preference], tolerance~ : Double = 1.0e-10) -> PrometheeResult raise ChoiceError {
  let w = matrix_weights(m, weights)
  preference_specs(m, preferences)
  let (n, p) = m.shape()
  let pi = zeros(n, n)
  for i in 0..<n {
    for k in 0..<n {
      if i == k { continue }
      let terms = Array::make(p, 0.0)
      for j in 0..<p {
        let delta = if m.directions[j] == Benefit { m.cells[i][j] - m.cells[k][j] } else { m.cells[k][j] - m.cells[i][j] }
        terms[j] = w[j] * preference_unchecked(preferences[j], delta)
      }
      pi[i][k] = sum(terms)
    }
  }
  let positive_flow = Array::make(n, 0.0)
  let negative_flow = Array::make(n, 0.0)
  let net = Array::make(n, 0.0)
  if n > 1 {
    let denominator = (n - 1).to_double()
    for i in 0..<n {
      positive_flow[i] = sum(pi[i]) / denominator
      negative_flow[i] = sum([ for k in 0..<n => pi[k][i] ]) / denominator
      net[i] = positive_flow[i] - negative_flow[i]
    }
  }
  { ranking: rank_scores(m.names, net, tolerance~), preference_matrix: pi, positive_flow, negative_flow }
}
