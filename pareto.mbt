///|
pub(all) struct ParetoResult {
  fronts : Array[Array[String]]
  front_indices : Array[Int]
  dominated_by : Array[Array[Int]]
} derive(@debug.Debug)

///|
fn dominates(m : DecisionMatrix, a : Int, b : Int) -> Bool {
  let mut strictly = false
  for j in 0..<m.criteria.length() {
    let x = m.cells[a][j]
    let y = m.cells[b][j]
    if m.directions[j] == Benefit {
      if x < y { return false }
      if x > y { strictly = true }
    } else {
      if x > y { return false }
      if x < y { strictly = true }
    }
  }
  strictly
}

///|
/// Exact dominance, intentionally without tolerance that could break transitivity.
pub fn pareto_fronts(m : DecisionMatrix) -> ParetoResult {
  let n = m.names.length()
  let dominated_by : Array[Array[Int]] = [ for _ in 0..<n => [] ]
  let successors : Array[Array[Int]] = [ for _ in 0..<n => [] ]
  for a in 0..<n {
    for b in 0..<n {
      if a != b && dominates(m, a, b) {
        dominated_by[b].push(a)
        successors[a].push(b)
      }
    }
  }
  let remaining = dominated_by.map(row => row.length())
  let front_indices = Array::make(n, -1)
  let fronts : Array[Array[String]] = []
  let mut current = [ for i in 0..<n if remaining[i] == 0 => i ]
  while current.length() > 0 {
    let index = fronts.length()
    fronts.push(current.map(i => m.names[i]))
    for i in current { front_indices[i] = index }
    for i in current {
      for k in successors[i] { remaining[k] -= 1 }
    }
    current = [ for i in 0..<n if front_indices[i] == -1 && remaining[i] == 0 => i ]
  }
  { fronts, front_indices, dominated_by }
}

///|
pub extend ParetoResult with @debug.Debug::{to_repr}
