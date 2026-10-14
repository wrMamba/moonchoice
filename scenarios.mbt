///|
pub(all) struct ScenarioReport {
  rankings : Array[Ranking]
  rank_counts : Array[Array[Int]]
  winner_counts : Array[Int]
  mean_ranks : Array[Double]
  best_ranks : Array[Int]
  worst_ranks : Array[Int]
  universally_best : Array[String]
  pairwise_wins : Array[Array[Int]]
  pairwise_ties : Array[Array[Int]]
} derive(Debug)

///|
/// Frequencies describe only the supplied finite scenario grid, not probabilities.
pub fn weight_scenarios(m : DecisionMatrix, scenarios : Array[Array[Double]], method : Method, tolerance~ : Double = 1.0e-10) -> ScenarioReport raise ChoiceError {
  let (n, p) = m.shape()
  let count = scenarios.length()
  if count == 0 || count > 64 { raise Budget("scenario count must be 1..64") }
  if n * n * p * count > 16777216 { raise Budget("scenario work exceeds 16777216 cell comparisons") }
  let rankings = scenarios.map(w => evaluate(m, w, method, tolerance~))
  let rank_counts : Array[Array[Int]] = [ for _ in 0..<n => Array::make(n, 0) ]
  let winner_counts = Array::make(n, 0)
  let mean_ranks = Array::make(n, 0.0)
  let best_ranks = Array::make(n, n)
  let worst_ranks = Array::make(n, 1)
  let pairwise_wins : Array[Array[Int]] = [ for _ in 0..<n => Array::make(n, 0) ]
  let pairwise_ties : Array[Array[Int]] = [ for _ in 0..<n => Array::make(n, 0) ]
  for ranking in rankings {
    for i in 0..<n {
      let rank = ranking.ranks[i]
      rank_counts[i][rank - 1] += 1
      if rank == 1 { winner_counts[i] += 1 }
      mean_ranks[i] += rank.to_double() / count.to_double()
      if rank < best_ranks[i] { best_ranks[i] = rank }
      if rank > worst_ranks[i] { worst_ranks[i] = rank }
      for j in 0..<n {
        if i == j { continue }
        if rank < ranking.ranks[j] { pairwise_wins[i][j] += 1 }
        else if rank == ranking.ranks[j] { pairwise_ties[i][j] += 1 }
      }
    }
  }
  let universally_best = [ for i in 0..<n if winner_counts[i] == count => m.names[i] ]
  { rankings, rank_counts, winner_counts, mean_ranks, best_ranks, worst_ranks, universally_best, pairwise_wins, pairwise_ties }
}

///|
/// Vary one weight, redistributing the rest proportionally to baseline weights.
pub fn weight_grid(weights : Array[Double], criterion : Int, values : Array[Double]) -> Array[Array[Double]] raise ChoiceError {
  let base = normalize_weights(weights)
  if criterion < 0 || criterion >= base.length() { raise Invalid("criterion index out of range") }
  if values.length() == 0 || values.length() > 64 { raise Budget("grid size must be 1..64") }
  let rest = sum([ for j in 0..<base.length() if j != criterion => base[j] ])
  let result : Array[Array[Double]] = []
  for value in values {
    probability(value)
    let row = Array::make(base.length(), 0.0)
    if base.length() == 1 && value != 1.0 { raise Invalid("single criterion weight must be one") }
    row[criterion] = value
    for j in 0..<base.length() {
      if j == criterion { continue }
      row[j] = if rest > 0.0 { (1.0 - value) * base[j] / rest } else { (1.0 - value) / (base.length() - 1).to_double() }
    }
    result.push(row)
  }
  result
}
