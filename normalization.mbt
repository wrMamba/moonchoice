///|
pub(all) enum Normalization {
  MinMax
  Vector
} derive(@debug.Debug, Eq)

///|
pub fn normalize_weights(
  weights : Array[Double],
) -> Array[Double] raise ChoiceError {
  if weights.length() == 0 || weights.length() > 32 {
    raise Budget("weight count must be 1..32")
  }
  for weight in weights {
    input_number(weight)
    if weight < 0.0 {
      raise Invalid("weights must be nonnegative")
    }
  }
  let scale = maximum(weights)
  if scale == 0.0 {
    raise Invalid("at least one weight must be positive")
  }
  let scaled = weights.map(w => w / scale)
  let total = sum(scaled)
  scaled.map(w => w / total)
}

///|
fn matrix_weights(
  m : DecisionMatrix,
  weights : Array[Double],
) -> Array[Double] raise ChoiceError {
  if weights.length() != m.criteria.length() {
    raise Invalid("weight count differs from criterion count")
  }
  normalize_weights(weights)
}

///|
/// Benefit-oriented values. Vector-normalized cost criteria are negated.
pub fn DecisionMatrix::normalize(
  self : DecisionMatrix,
  mode : Normalization,
) -> Array[Array[Double]] raise ChoiceError {
  let (n, p) = self.shape()
  let out = zeros(n, p)
  for j in 0..<p {
    let col = self.column(j)
    match mode {
      MinMax => {
        let low = minimum(col)
        let high = maximum(col)
        let span = high - low
        for i in 0..<n {
          out[i][j] = if span == 0.0 {
            0.0
          } else if self.directions[j] == Benefit {
            (col[i] - low) / span
          } else {
            (high - col[i]) / span
          }
        }
      }
      Vector => {
        let scale = maximum(col.map(x => x.abs()))
        if scale > 0.0 {
          let square_sum = sum(
            col.map(x => {
              let y = x / scale
              y * y
            }),
          )
          let norm = square_sum.sqrt()
          let sign = if self.directions[j] == Benefit { 1.0 } else { -1.0 }
          for i in 0..<n {
            out[i][j] = sign * (col[i] / scale) / norm
          }
        }
      }
    }
  }
  out
}

///|
pub extend Normalization with @debug.Debug::{to_repr}

///|
pub extend Normalization with Eq::{equal, not_equal}
