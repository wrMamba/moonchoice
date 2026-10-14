///|
pub(all) enum Direction {
  Benefit
  Cost
} derive(@debug.Debug, Eq)

///|
/// Validated immutable matrix; all array accessors return defensive copies.
pub struct DecisionMatrix {
  names : Array[String]
  criteria : Array[String]
  directions : Array[Direction]
  cells : Array[Array[Double]]
}

///|
fn valid_labels(
  labels : Array[String],
  max_count : Int32,
) -> Unit raise ChoiceError {
  if labels.length() == 0 || labels.length() > max_count {
    raise Budget("label count outside supported shape")
  }
  for i, name in labels {
    if name.trim().length() == 0 || name.length() > 128 {
      raise Invalid("labels must contain 1..128 code units and nonblank text")
    }
    for j in 0..<i {
      if labels[j] == name {
        raise Invalid("duplicate label")
      }
    }
  }
}

///|
pub fn decision_matrix(
  alternatives : Array[String],
  criteria : Array[String],
  directions : Array[Direction],
  values : Array[Array[Double]],
) -> DecisionMatrix raise ChoiceError {
  valid_labels(alternatives, 256)
  valid_labels(criteria, 32)
  if directions.length() != criteria.length() {
    raise Invalid("criterion direction count mismatch")
  }
  if values.length() != alternatives.length() {
    raise Invalid("alternative row count mismatch")
  }
  for row in values {
    if row.length() != criteria.length() {
      raise Invalid("ragged decision matrix")
    }
    for value in row {
      input_number(value)
    }
  }
  {
    names: alternatives.copy(),
    criteria: criteria.copy(),
    directions: directions.copy(),
    cells: values.map(row => row.copy()),
  }
}

///|
pub fn DecisionMatrix::alternatives(self : DecisionMatrix) -> Array[String] {
  self.names.copy()
}

///|
pub fn DecisionMatrix::criterion_names(self : DecisionMatrix) -> Array[String] {
  self.criteria.copy()
}

///|
pub fn DecisionMatrix::criterion_directions(
  self : DecisionMatrix,
) -> Array[Direction] {
  self.directions.copy()
}

///|
pub fn DecisionMatrix::values(self : DecisionMatrix) -> Array[Array[Double]] {
  self.cells.map(row => row.copy())
}

///|
pub fn DecisionMatrix::shape(self : DecisionMatrix) -> (Int32, Int32) {
  (self.names.length(), self.criteria.length())
}

///|
pub fn DecisionMatrix::cell(
  self : DecisionMatrix,
  row : Int32,
  column : Int32,
) -> Double raise ChoiceError {
  if row < 0 ||
    row >= self.names.length() ||
    column < 0 ||
    column >= self.criteria.length() {
    raise Invalid("matrix index out of bounds")
  }
  self.cells[row][column]
}

///|
pub fn DecisionMatrix::column(
  self : DecisionMatrix,
  column : Int32,
) -> Array[Double] raise ChoiceError {
  if column < 0 || column >= self.criteria.length() {
    raise Invalid("criterion index out of bounds")
  }
  self.cells.map(row => row[column])
}

///|
pub extend Direction with @debug.Debug::{to_repr}

///|
pub extend Direction with Eq::{equal, not_equal}
