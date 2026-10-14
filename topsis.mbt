///|
pub(all) struct TopsisResult {
  ranking : Ranking
  normalized : Array[Array[Double]]
  weighted : Array[Array[Double]]
  ideal : Array[Double]
  anti_ideal : Array[Double]
  distance_ideal : Array[Double]
  distance_anti_ideal : Array[Double]
} derive(Debug)

///|
pub fn topsis(m : DecisionMatrix, weights : Array[Double], normalization~ : Normalization = MinMax, tolerance~ : Double = 1.0e-10) -> TopsisResult raise ChoiceError {
  let w = matrix_weights(m, weights)
  let x = m.normalize(normalization)
  let (n, p) = m.shape()
  let weighted = zeros(n, p)
  let ideal = Array::make(p, 0.0)
  let anti_ideal = Array::make(p, 0.0)
  for j in 0..<p {
    let col = [ for i in 0..<n => x[i][j] * w[j] ]
    ideal[j] = maximum(col)
    anti_ideal[j] = minimum(col)
    for i in 0..<n { weighted[i][j] = col[i] }
  }
  let distance_ideal = Array::make(n, 0.0)
  let distance_anti_ideal = Array::make(n, 0.0)
  let scores = Array::make(n, 0.0)
  for i in 0..<n {
    let dp = Array::make(p, 0.0)
    let dm = Array::make(p, 0.0)
    for j in 0..<p {
      let a = weighted[i][j] - ideal[j]
      let b = weighted[i][j] - anti_ideal[j]
      dp[j] = a * a
      dm[j] = b * b
    }
    distance_ideal[i] = sum(dp).sqrt()
    distance_anti_ideal[i] = sum(dm).sqrt()
    let total = distance_ideal[i] + distance_anti_ideal[i]
    // All alternatives identical: undefined 0/0 becomes an explicit neutral tie.
    scores[i] = if total == 0.0 { 0.5 } else { distance_anti_ideal[i] / total }
  }
  { ranking: rank_scores(m.names, scores, tolerance~), normalized: x, weighted, ideal, anti_ideal, distance_ideal, distance_anti_ideal }
}
