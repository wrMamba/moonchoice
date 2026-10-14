///|
pub(all) enum Method {
  Additive(Normalization)
  IdealDistance(Normalization)
  Product
  Compromise(Double)
  Outranking(Array[Preference])
} derive(Debug)

///|
pub fn evaluate(m : DecisionMatrix, weights : Array[Double], method : Method, tolerance~ : Double = 1.0e-10) -> Ranking raise ChoiceError {
  match method {
    Additive(normalization) => saw(m, weights, normalization~, tolerance~).ranking
    IdealDistance(normalization) => topsis(m, weights, normalization~, tolerance~).ranking
    Product => weighted_product(m, weights, tolerance~).ranking
    Compromise(v) => vikor(m, weights, v~, tolerance~).ranking
    Outranking(preferences) => promethee(m, weights, preferences, tolerance~).ranking
  }
}

///|
pub(all) struct MethodComparison {
  rankings : Array[Ranking]
  agreements : Array[Array[RankAgreement]]
} derive(Debug)

///|
pub fn compare_methods(m : DecisionMatrix, weights : Array[Double], methods : Array[Method], tolerance~ : Double = 1.0e-10) -> MethodComparison raise ChoiceError {
  if methods.length() == 0 || methods.length() > 16 { raise Budget("method count must be 1..16") }
  let rankings = methods.map(method => evaluate(m, weights, method, tolerance~))
  let agreements = rankings.map(a => rankings.map(b => rank_agreement(a, b)))
  { rankings, agreements }
}
