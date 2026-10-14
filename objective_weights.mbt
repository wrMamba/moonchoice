///|
pub(all) struct WeightEstimate {
  weights : Array[Double]
  information : Array[Double]
  uniform_fallback : Bool
} derive(@debug.Debug)

///|
fn weight_estimate(
  information : Array[Double],
) -> WeightEstimate raise ChoiceError {
  let no_information = maximum(information) == 0.0
  let weights = if no_information {
    Array::make(information.length(), 1.0 / information.length().to_double())
  } else {
    normalize_weights(information)
  }
  { weights, information, uniform_fallback: no_information, }
}

///|
fn column_moments(x : Array[Array[Double]], j : Int32) -> (Double, Double) {
  let values = x.map(row => row[j])
  let mean = sum(values) / x.length().to_double()
  let variance = sum(
      values.map(v => {
        let d = v - mean
        d * d
      }),
    ) /
    x.length().to_double()
  (mean, variance.sqrt())
}

///|
/// Entropy of benefit-oriented minmax columns; all-zero columns are uninformative.
pub fn entropy_weights(m : DecisionMatrix) -> WeightEstimate raise ChoiceError {
  let x = m.normalize(MinMax)
  let (n, p) = m.shape()
  let information = Array::make(p, 0.0)
  if n > 1 {
    let log_n = @math.ln(n.to_double())
    for j in 0..<p {
      let col = x.map(row => row[j])
      let total = sum(col)
      if total > 0.0 {
        let mut entropy = 0.0
        for value in col {
          let probability = value / total
          if probability > 0.0 {
            entropy -= probability * @math.ln(probability)
          }
        }
        let divergence = 1.0 - entropy / log_n
        information[j] = if divergence < 0.0 { 0.0 } else { divergence }
      }
    }
  }
  weight_estimate(information)
}

///|
/// Population dispersion in benefit-oriented minmax units, not physical units.
pub fn deviation_weights(
  m : DecisionMatrix,
) -> WeightEstimate raise ChoiceError {
  let x = m.normalize(MinMax)
  let information = [
    for j in 0..<m.criteria.length() => {
      let (_, deviation) = column_moments(x, j)
      deviation
    }
  ]
  weight_estimate(information)
}

///|
pub fn critic_weights(m : DecisionMatrix) -> WeightEstimate raise ChoiceError {
  let x = m.normalize(MinMax)
  let (n, p) = m.shape()
  let means = Array::make(p, 0.0)
  let deviations = Array::make(p, 0.0)
  for j in 0..<p {
    let (mean, deviation) = column_moments(x, j)
    means[j] = mean
    deviations[j] = deviation
  }
  let information = Array::make(p, 0.0)
  for j in 0..<p {
    let mut conflict = 0.0
    if deviations[j] == 0.0 {
      continue
    }
    for k in 0..<p {
      if j == k || deviations[k] == 0.0 {
        continue
      }
      let products = [
        for i in 0..<n => (x[i][j] - means[j]) * (x[i][k] - means[k])
      ]
      let correlation = sum(products) /
        (n.to_double() * deviations[j] * deviations[k])
      let bounded = if correlation > 1.0 {
        1.0
      } else if correlation < -1.0 {
        -1.0
      } else {
        correlation
      }
      conflict += 1.0 - bounded
    }
    information[j] = deviations[j] * conflict
  }
  // A single informative criterion, or perfectly correlated criteria, carries no
  // contrast information under CRITIC. The explicit fallback is uniform.
  weight_estimate(information)
}

///|
pub extend WeightEstimate with @debug.Debug::{to_repr}
