///|
pub(all) struct CriterionProfile {
  name : String
  direction : Direction
  minimum : Double
  maximum : Double
  mean : Double
  population_deviation : Double
  distinct_values : Int
  constant : Bool
  normalized_weight : Double
} derive(@debug.Debug)

///|
/// Observed ranges and scaled population deviations, not confidence estimates.
pub fn criterion_profiles(
  m : DecisionMatrix,
  weights : Array[Double],
) -> Array[CriterionProfile] raise ChoiceError {
  let w = matrix_weights(m, weights)
  let result : Array[CriterionProfile] = []
  for j, name in m.criteria {
    let x = m.cells.map(row => row[j])
    let lo = minimum(x)
    let hi = maximum(x)
    let scale = maximum(x.map(v => v.abs()))
    let scaled = x.map(v => if scale == 0.0 { 0.0 } else { v / scale })
    let center = sum(scaled) / x.length().to_double()
    let variance = sum(scaled.map(v => (v - center) * (v - center))) /
      x.length().to_double()
    let distinct : Array[Double] = []
    for value in x {
      if !distinct.contains(value) {
        distinct.push(value)
      }
    }
    result.push({
      name,
      direction: m.directions[j],
      minimum: lo,
      maximum: hi,
      mean: checked(center * scale),
      population_deviation: checked(variance.sqrt() * scale),
      distinct_values: distinct.length(),
      constant: lo == hi,
      normalized_weight: w[j],
    })
  }
  result
}

///|
pub(all) struct CriterionRemoval {
  omitted : String
  remaining_criteria : Array[String]
  ranking : Ranking
  agreement : RankAgreement
  winner_changed : Bool
} derive(@debug.Debug)

///|
pub(all) struct CriterionSensitivity {
  baseline : Ranking
  removals : Array[CriterionRemoval]
  skipped_zero_weight_remainders : Array[String]
} derive(@debug.Debug)

///|
/// Recomputes each leave-one-criterion-out model; zero remaining weight is recorded.
pub fn criterion_sensitivity(
  m : DecisionMatrix,
  weights : Array[Double],
  algorithm : Method,
) -> CriterionSensitivity raise ChoiceError {
  let w = matrix_weights(m, weights)
  if m.criteria.length() < 2 {
    raise Invalid("criterion removal needs at least two criteria")
  }
  let baseline = evaluate(m, w, algorithm)
  let removals : Array[CriterionRemoval] = []
  let skipped_zero_weight_remainders : Array[String] = []
  for omitted in 0..<m.criteria.length() {
    let indices = [ for j in 0..<m.criteria.length() if j != omitted => j ]
    let remaining_weights = indices.map(j => w[j])
    if sum(remaining_weights) == 0.0 {
      skipped_zero_weight_remainders.push(m.criteria[omitted])
      continue
    }
    let subset = m.select_criteria(indices)
    let reduced_algorithm = match algorithm {
      Outranking(preferences) => {
        preference_specs(m, preferences)
        Outranking(indices.map(j => preferences[j]))
      }
      other => other
    }
    let ranking = evaluate(subset, remaining_weights, reduced_algorithm)
    removals.push({
      omitted: m.criteria[omitted],
      remaining_criteria: subset.criteria.copy(),
      ranking,
      agreement: rank_agreement(baseline, ranking),
      winner_changed: baseline.winners() != ranking.winners(),
    })
  }
  { baseline, removals, skipped_zero_weight_remainders, }
}

///|
pub(all) struct DecisionReport {
  ranking : Ranking
  weights : Array[Double]
  profiles : Array[CriterionProfile]
  pareto : ParetoResult
  additive_contributions : Array[Array[Double]]
  warnings : Array[String]
} derive(@debug.Debug)

///|
/// Auxiliary additive contributions are a separate diagnostic, not every method's score.
pub fn decision_report(
  m : DecisionMatrix,
  weights : Array[Double],
  algorithm : Method,
) -> DecisionReport raise ChoiceError {
  let w = matrix_weights(m, weights)
  let profiles = criterion_profiles(m, w)
  let ranking = evaluate(m, w, algorithm)
  let warnings : Array[String] = []
  for profile in profiles {
    if profile.constant && profile.normalized_weight > 0.0 {
      warnings.push("positive weight on constant criterion: " + profile.name)
    }
  }
  if ranking.winners().length() > 1 {
    warnings.push("multiple alternatives share the first competition rank")
  }
  warnings.push(
    "ranking is conditional on the observed alternatives and stated preferences",
  )
  let additive_contributions = saw(m, w).contributions
  {
    ranking,
    weights: w,
    profiles,
    pareto: pareto_fronts(m),
    additive_contributions,
    warnings,
  }
}

///|
pub fn report_json(report : DecisionReport) -> Json raise ChoiceError {
  let profiles = report.profiles.map(p => {
    Json::object({
      "name": p.name.to_json(),
      "direction": (if p.direction == Benefit { "benefit" } else { "cost" }).to_json(),
      "minimum": p.minimum.to_json(),
      "maximum": p.maximum.to_json(),
      "mean": p.mean.to_json(),
      "population_deviation": p.population_deviation.to_json(),
      "distinct_values": p.distinct_values.to_json(),
      "constant": p.constant.to_json(),
      "normalized_weight": p.normalized_weight.to_json(),
    })
  })
  Json::object({
    "schema": "moonchoice.report/1".to_json(),
    "ranking": ranking_json(report.ranking),
    "weights": report.weights.to_json(),
    "profiles": Json::array(profiles),
    "pareto_fronts": report.pareto.fronts.to_json(),
    "additive_minmax_contributions": report.additive_contributions.to_json(),
    "warnings": report.warnings.to_json(),
  })
}

///|
pub extend CriterionProfile with @debug.Debug::{to_repr}

///|
pub extend CriterionRemoval with @debug.Debug::{to_repr}

///|
pub extend CriterionSensitivity with @debug.Debug::{to_repr}

///|
pub extend DecisionReport with @debug.Debug::{to_repr}
