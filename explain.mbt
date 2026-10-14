///|
pub(all) struct CriterionComparison {
  criterion : String
  left_value : Double
  right_value : Double
  oriented_difference : Double
  weighted_preference_left : Double
  weighted_preference_right : Double
} derive(@debug.Debug)

///|
pub(all) struct PairExplanation {
  left : String
  right : String
  criteria : Array[CriterionComparison]
  aggregate_left : Double
  aggregate_right : Double
  net_preference : Double
  left_dominates : Bool
  right_dominates : Bool
} derive(@debug.Debug)

///|
pub fn explain_pair(m : DecisionMatrix, weights : Array[Double], preferences : Array[Preference], left : Int, right : Int) -> PairExplanation raise ChoiceError {
  let w = matrix_weights(m, weights)
  preference_specs(m, preferences)
  if left < 0 || left >= m.names.length() || right < 0 || right >= m.names.length() { raise Invalid("alternative index out of bounds") }
  let criteria : Array[CriterionComparison] = []
  for j in 0..<m.criteria.length() {
    let left_value = m.cells[left][j]
    let right_value = m.cells[right][j]
    let oriented_difference = if m.directions[j] == Benefit { left_value - right_value } else { right_value - left_value }
    criteria.push({ criterion: m.criteria[j], left_value, right_value, oriented_difference, weighted_preference_left: w[j] * preference_unchecked(preferences[j], oriented_difference), weighted_preference_right: w[j] * preference_unchecked(preferences[j], -oriented_difference) })
  }
  let aggregate_left = sum(criteria.map(c => c.weighted_preference_left))
  let aggregate_right = sum(criteria.map(c => c.weighted_preference_right))
  { left: m.names[left], right: m.names[right], criteria, aggregate_left, aggregate_right, net_preference: aggregate_left - aggregate_right, left_dominates: dominates(m, left, right), right_dominates: dominates(m, right, left) }
}

///|
pub(all) struct AdditiveBreakEven {
  intercept : Double
  slope : Double
  crossing : Double?
  tied_for_all_weights : Bool
} derive(@debug.Debug)

///|
/// Exact SAW one-coordinate weight-grid crossing for a fixed normalization matrix.
pub fn additive_break_even(m : DecisionMatrix, weights : Array[Double], criterion : Int, left : Int, right : Int) -> AdditiveBreakEven raise ChoiceError {
  let w = matrix_weights(m, weights)
  if criterion < 0 || criterion >= w.length() { raise Invalid("criterion index out of range") }
  let _ = m.cell(left, criterion)
  let _ = m.cell(right, criterion)
  let x = m.normalize(MinMax)
  let rest = sum([ for j in 0..<w.length() if j != criterion => w[j] ])
  let mut intercept = 0.0
  for j in 0..<w.length() {
    if j == criterion { continue }
    let share = if rest > 0.0 { w[j] / rest } else { 1.0 / (w.length() - 1).to_double() }
    intercept += share * (x[left][j] - x[right][j])
  }
  let slope = x[left][criterion] - x[right][criterion] - intercept
  let root = if slope == 0.0 { None } else {
    let value = -intercept / slope
    if value >= 0.0 && value <= 1.0 { Some(value) } else { None }
  }
  { intercept, slope, crossing: root, tied_for_all_weights: intercept == 0.0 && slope == 0.0 }
}

///|
pub extend CriterionComparison with @debug.Debug::{to_repr}

///|
pub extend PairExplanation with @debug.Debug::{to_repr}

///|
pub extend AdditiveBreakEven with @debug.Debug::{to_repr}
