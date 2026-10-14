///|
pub(all) struct Ranking {
  labels : Array[String]
  scores : Array[Double]
  order : Array[Int32]
  ranks : Array[Int32]
  higher_is_better : Bool
  tie_tolerance : Double
} derive(@debug.Debug)

///|
/// Stable exact sort, followed by anchor-based competition-rank tie groups.
pub fn rank_scores(
  labels : Array[String],
  scores : Array[Double],
  higher_is_better~ : Bool = true,
  tolerance~ : Double = 1.0e-10,
) -> Ranking raise ChoiceError {
  valid_labels(labels, 256)
  valid_tolerance(tolerance)
  if scores.length() != labels.length() {
    raise Invalid("score and label counts differ")
  }
  for x in scores {
    let _ = checked(x)
  }
  let order = [ for i in 0..<scores.length() => i ]
  for i in 1..<order.length() {
    let item = order[i]
    let mut j = i
    while j > 0 {
      let before = order[j - 1]
      let better = if higher_is_better {
        scores[item] > scores[before]
      } else {
        scores[item] < scores[before]
      }
      if !better {
        break
      }
      order[j] = before
      j -= 1
    }
    order[j] = item
  }
  let ranks = Array::make(scores.length(), 1)
  let mut group_start = 0
  for k, index in order {
    if (scores[index] - scores[order[group_start]]).abs() > tolerance {
      group_start = k
    }
    ranks[index] = group_start + 1
  }
  {
    labels: labels.copy(),
    scores: scores.copy(),
    order,
    ranks,
    higher_is_better,
    tie_tolerance: tolerance,
  }
}

///|
fn validated_ranking(r : Ranking) -> Ranking raise ChoiceError {
  let canonical = rank_scores(
    r.labels,
    r.scores,
    higher_is_better=r.higher_is_better,
    tolerance=r.tie_tolerance,
  )
  if canonical.order != r.order || canonical.ranks != r.ranks {
    raise Invalid("ranking order/ranks do not match scores")
  }
  canonical
}

///|
pub fn Ranking::winners(self : Ranking) -> Array[String] raise ChoiceError {
  let r = validated_ranking(self)
  [
    for index in r.order if r.ranks[index] == 1 => r.labels[index]
  ]
}

///|
pub fn Ranking::top(
  self : Ranking,
  count : Int32,
) -> Array[String] raise ChoiceError {
  let r = validated_ranking(self)
  if count < 0 || count > r.order.length() {
    raise Invalid("requested top count out of range")
  }
  [
    for k in 0..<count => r.labels[r.order[k]]
  ]
}

///|
pub extend Ranking with @debug.Debug::{to_repr}
