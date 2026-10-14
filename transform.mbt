///|
fn selection(indices : Array[Int32], count : Int32) -> Unit raise ChoiceError {
  if indices.length() == 0 {
    raise Invalid("selection must not be empty")
  }
  for i, index in indices {
    if index < 0 || index >= count {
      raise Invalid("selection index out of bounds")
    }
    for j in 0..<i {
      if indices[j] == index {
        raise Invalid("duplicate selection index")
      }
    }
  }
}

///|
pub fn DecisionMatrix::select_alternatives(
  self : DecisionMatrix,
  indices : Array[Int32],
) -> DecisionMatrix raise ChoiceError {
  selection(indices, self.names.length())
  decision_matrix(
    indices.map(i => self.names[i]),
    self.criteria,
    self.directions,
    indices.map(i => self.cells[i]),
  )
}

///|
pub fn DecisionMatrix::select_criteria(
  self : DecisionMatrix,
  indices : Array[Int32],
) -> DecisionMatrix raise ChoiceError {
  selection(indices, self.criteria.length())
  decision_matrix(
    self.names,
    indices.map(i => self.criteria[i]),
    indices.map(i => self.directions[i]),
    self.cells.map(row => indices.map(j => row[j])),
  )
}

///|
/// Affine unit conversion must be strictly increasing; directions stay unchanged.
pub fn DecisionMatrix::convert_units(
  self : DecisionMatrix,
  scales : Array[Double],
  offsets : Array[Double],
) -> DecisionMatrix raise ChoiceError {
  let (n, p) = self.shape()
  if scales.length() != p || offsets.length() != p {
    raise Invalid("unit transform shape mismatch")
  }
  for j in 0..<p {
    input_number(scales[j])
    input_number(offsets[j])
    if scales[j] <= 0.0 {
      raise Invalid("unit scales must be strictly positive")
    }
  }
  let values = zeros(n, p)
  for i in 0..<n {
    for j in 0..<p {
      values[i][j] = checked(self.cells[i][j] * scales[j] + offsets[j])
    }
  }
  decision_matrix(self.names, self.criteria, self.directions, values)
}

///|
pub(all) struct RemovalAnalysis {
  removed : String
  baseline : Ranking
  remaining : Ranking
  agreement : RankAgreement
  winner_changed : Bool
} derive(@debug.Debug)

///|
/// Reports actual rank reversal when removing an alternative changes normalization.
pub fn removal_analysis(
  m : DecisionMatrix,
  weights : Array[Double],
  algorithm : Method,
  removed : Int32,
) -> RemovalAnalysis raise ChoiceError {
  let n = m.names.length()
  if n < 2 || removed < 0 || removed >= n {
    raise Invalid(
      "removal requires at least two alternatives and a valid index",
    )
  }
  let baseline = evaluate(m, weights, algorithm)
  let indices = [ for i in 0..<n if i != removed => i ]
  let subset = m.select_alternatives(indices)
  let remaining = evaluate(subset, weights, algorithm)
  let projected = rank_scores(
    subset.names,
    indices.map(i => baseline.scores[i]),
    higher_is_better=baseline.higher_is_better,
    tolerance=baseline.tie_tolerance,
  )
  let agreement = rank_agreement(projected, remaining)
  let winner_changed = projected.winners() != remaining.winners()
  { removed: m.names[removed], baseline, remaining, agreement, winner_changed, }
}

///|
pub extend RemovalAnalysis with @debug.Debug::{to_repr}
