///|
pub(all) struct ProductResult {
  ranking : Ranking
  log_contributions : Array[Array[Double]]
  relative_products : Array[Double]
} derive(@debug.Debug)

///|
/// Scores are log products; relative_products are exp(score - best_score).
pub fn weighted_product(
  m : DecisionMatrix,
  weights : Array[Double],
  tolerance~ : Double = 1.0e-10,
) -> ProductResult raise ChoiceError {
  let w = matrix_weights(m, weights)
  let (n, p) = m.shape()
  let terms = zeros(n, p)
  for j in 0..<p {
    let col = m.column(j)
    for x in col {
      if x <= 0.0 {
        raise Invalid("weighted product requires strictly positive values")
      }
    }
    let reference = if m.directions[j] == Benefit {
      maximum(col)
    } else {
      minimum(col)
    }
    let reference_log = @math.ln(reference)
    for i in 0..<n {
      let delta = @math.ln(col[i]) - reference_log
      terms[i][j] = if m.directions[j] == Benefit {
        w[j] * delta
      } else {
        -w[j] * delta
      }
    }
  }
  let scores = terms.map(row => checked(sum(row)))
  let best = maximum(scores)
  let relative_products = scores.map(x => @math.exp(x - best))
  {
    ranking: rank_scores(m.names, scores, tolerance~),
    log_contributions: terms,
    relative_products,
  }
}

///|
pub extend ProductResult with @debug.Debug::{to_repr}
