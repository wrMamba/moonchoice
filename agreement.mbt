///|
pub(all) struct RankAgreement {
  spearman : Double?
  kendall_tau_b : Double?
  concordant_pairs : Int
  discordant_pairs : Int
  shared_winners : Array[String]
} derive(@debug.Debug)

///|
fn aligned_indices(a : Ranking, b : Ranking) -> Array[Int] raise ChoiceError {
  if a.labels.length() != b.labels.length() {
    raise Invalid("ranking label sets differ")
  }
  let indices : Array[Int] = []
  for label in a.labels {
    let mut found = -1
    for j, candidate in b.labels {
      if label == candidate {
        found = j
        break
      }
    }
    if found < 0 {
      raise Invalid("ranking label sets differ")
    }
    indices.push(found)
  }
  indices
}

///|
fn midranks(r : Ranking) -> Array[Double] {
  r.ranks.map(rank => {
    let count = r.ranks.filter(value => value == rank).length()
    rank.to_double() + (count - 1).to_double() / 2.0
  })
}

///|
pub fn rank_agreement(
  left : Ranking,
  right : Ranking,
) -> RankAgreement raise ChoiceError {
  let a = validated_ranking(left)
  let b = validated_ranking(right)
  let indices = aligned_indices(a, b)
  let x = midranks(a)
  let rb = midranks(b)
  let y = indices.map(i => rb[i])
  let n = x.length()
  let xm = sum(x) / n.to_double()
  let ym = sum(y) / n.to_double()
  let mut xx = 0.0
  let mut yy = 0.0
  let mut xy = 0.0
  let mut concordant_pairs = 0
  let mut discordant_pairs = 0
  let mut tied_left = 0
  let mut tied_right = 0
  for i in 0..<n {
    xx += (x[i] - xm) * (x[i] - xm)
    yy += (y[i] - ym) * (y[i] - ym)
    xy += (x[i] - xm) * (y[i] - ym)
    for j in (i + 1)..<n {
      let dx = x[i] - x[j]
      let dy = y[i] - y[j]
      if dx == 0.0 && dy == 0.0 {
        continue
      }
      if dx == 0.0 {
        tied_left += 1
      } else if dy == 0.0 {
        tied_right += 1
      } else if dx * dy > 0.0 {
        concordant_pairs += 1
      } else {
        discordant_pairs += 1
      }
    }
  }
  let spearman = if xx == 0.0 || yy == 0.0 {
    None
  } else {
    Some(xy / (xx * yy).sqrt())
  }
  let comparable = concordant_pairs + discordant_pairs
  let denominator = ((comparable + tied_left).to_double() *
  (comparable + tied_right).to_double()).sqrt()
  let kendall_tau_b = if denominator == 0.0 {
    None
  } else {
    Some((concordant_pairs - discordant_pairs).to_double() / denominator)
  }
  let shared_winners = [
    for i in 0..<n if a.ranks[i] == 1 && b.ranks[indices[i]] == 1 => a.labels[i]
  ]
  {
    spearman,
    kendall_tau_b,
    concordant_pairs,
    discordant_pairs,
    shared_winners,
  }
}

///|
pub extend RankAgreement with @debug.Debug::{to_repr}
