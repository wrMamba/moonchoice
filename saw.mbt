///|
pub(all) struct AdditiveResult {
  ranking : Ranking
  normalized : Array[Array[Double]]
  contributions : Array[Array[Double]]
  weights : Array[Double]
} derive(Debug)

///|
pub fn saw(m : DecisionMatrix, weights : Array[Double], normalization~ : Normalization = MinMax, tolerance~ : Double = 1.0e-10) -> AdditiveResult raise ChoiceError {
  let w = matrix_weights(m, weights)
  let x = m.normalize(normalization)
  let (n, p) = m.shape()
  let contributions = zeros(n, p)
  let scores = Array::make(n, 0.0)
  for i in 0..<n {
    for j in 0..<p {
      contributions[i][j] = x[i][j] * w[j]
    }
    scores[i] = checked(sum(contributions[i]))
  }
  { ranking: rank_scores(m.names, scores, tolerance~), normalized: x, contributions, weights: w }
}
