///|
pub(all) struct VikorResult {
  ranking : Ranking
  utility : Array[Double]
  regret : Array[Double]
  criterion_regrets : Array[Array[Double]]
  compromise : Array[String]
  acceptable_advantage : Bool
  acceptable_stability : Bool
} derive(Debug)

///|
pub fn vikor(m : DecisionMatrix, weights : Array[Double], v~ : Double = 0.5, tolerance~ : Double = 1.0e-10) -> VikorResult raise ChoiceError {
  probability(v)
  let w = matrix_weights(m, weights)
  let x = m.normalize(MinMax)
  let (n, p) = m.shape()
  let losses = zeros(n, p)
  let utility = Array::make(n, 0.0)
  let regret = Array::make(n, 0.0)
  for j in 0..<p {
    let constant = maximum(m.column(j)) == minimum(m.column(j))
    for i in 0..<n {
      losses[i][j] = if constant { 0.0 } else { w[j] * (1.0 - x[i][j]) }
    }
  }
  for i in 0..<n {
    utility[i] = sum(losses[i])
    regret[i] = maximum(losses[i])
  }
  let slo = minimum(utility)
  let shi = maximum(utility)
  let rlo = minimum(regret)
  let rhi = maximum(regret)
  let scores = [ for i in 0..<n => {
    let s = if shi == slo { 0.0 } else { (utility[i] - slo) / (shi - slo) }
    let r = if rhi == rlo { 0.0 } else { (regret[i] - rlo) / (rhi - rlo) }
    v * s + (1.0 - v) * r
  } ]
  let ranking = rank_scores(m.names, scores, higher_is_better=false, tolerance~)
  let best = ranking.order[0]
  let acceptable_stability = utility[best] <= slo + tolerance || regret[best] <= rlo + tolerance
  let threshold = if n <= 1 { 0.0 } else { 1.0 / (n - 1).to_double() }
  let acceptable_advantage = n <= 1 || scores[ranking.order[1]] - scores[best] + tolerance >= threshold
  let compromise : Array[String] = []
  if acceptable_advantage && acceptable_stability {
    compromise.push(m.names[best])
  } else if acceptable_advantage {
    compromise.push(m.names[best])
    if n > 1 { compromise.push(m.names[ranking.order[1]]) }
  } else {
    for i in ranking.order {
      if scores[i] - scores[best] < threshold || ranking.ranks[i] == 1 {
        compromise.push(m.names[i])
      }
    }
  }
  { ranking, utility, regret, criterion_regrets: losses, compromise, acceptable_advantage, acceptable_stability }
}
