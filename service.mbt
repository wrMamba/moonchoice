///|
fn normalization_from_json(value : Json) -> Normalization raise ChoiceError {
  match json_string(value) {
    "minmax" => MinMax
    "vector" => Vector
    _ => raise Invalid("normalization must be minmax or vector")
  }
}

///|
fn preference_from_json(value : Json) -> Preference raise ChoiceError {
  let f = object_fields(value, ["kind", "q", "p", "sigma"])
  let kind = json_string(required(f, "kind"))
  let allowed = match kind {
    "usual" => ["kind"]
    "ushape" => ["kind", "q"]
    "vshape" => ["kind", "p"]
    "level" | "linear" => ["kind", "q", "p"]
    "gaussian" => ["kind", "sigma"]
    _ => raise Invalid("unsupported preference kind")
  }
  let _ = object_fields(value, allowed)
  let preference = match kind {
    "usual" => Usual
    "ushape" => UShape(json_number(required(f, "q")))
    "vshape" => VShape(json_number(required(f, "p")))
    "level" =>
      Level(json_number(required(f, "q")), json_number(required(f, "p")))
    "linear" =>
      Linear(json_number(required(f, "q")), json_number(required(f, "p")))
    _ => Gaussian(json_number(required(f, "sigma")))
  }
  valid_preference(preference)
  preference
}

///|
fn method_from_json(value : Json) -> Method raise ChoiceError {
  let f = object_fields(value, ["kind", "normalization", "v", "preferences"])
  let kind = json_string(required(f, "kind"))
  let allowed = match kind {
    "saw" | "topsis" => ["kind", "normalization"]
    "product" => ["kind"]
    "vikor" => ["kind", "v"]
    "promethee" => ["kind", "preferences"]
    _ => raise Invalid("unsupported algorithm kind")
  }
  let _ = object_fields(value, allowed)
  match kind {
    "saw" => Additive(normalization_from_json(required(f, "normalization")))
    "topsis" =>
      IdealDistance(normalization_from_json(required(f, "normalization")))
    "product" => Product
    "vikor" => {
      let v = json_number(required(f, "v"))
      probability(v)
      Compromise(v)
    }
    _ =>
      Outranking(
        json_array(required(f, "preferences"), 32).map(preference_from_json),
      )
  }
}

///|
fn scenario_json(report : ScenarioReport) -> Json raise ChoiceError {
  Json::object({
    "schema": Json("moonchoice.scenarios/1"),
    "rankings": Json::array(report.rankings.map(ranking_json)),
    "rank_counts": Json(report.rank_counts),
    "winner_counts": Json(report.winner_counts),
    "mean_ranks": Json(report.mean_ranks),
    "best_ranks": Json(report.best_ranks),
    "worst_ranks": Json(report.worst_ranks),
    "universally_best": Json(report.universally_best),
    "pairwise_wins": Json(report.pairwise_wins),
    "pairwise_ties": Json(report.pairwise_ties),
    "frequency_interpretation": Json(
      "finite supplied scenarios, not probabilities",
    ),
  })
}

///|
fn execute_request(value : Json) -> Json raise ChoiceError {
  let f = object_fields(value, [
    "schema", "operation", "matrix", "weights", "algorithm", "scenarios",
  ])
  if json_string(required(f, "schema")) != "moonchoice.request/1" {
    raise Invalid("unsupported request schema")
  }
  let operation = json_string(required(f, "operation"))
  let allowed = if operation == "scenarios" {
    ["schema", "operation", "matrix", "algorithm", "scenarios"]
  } else {
    ["schema", "operation", "matrix", "algorithm", "weights"]
  }
  let _ = object_fields(value, allowed)
  let m = matrix_from_json(required(f, "matrix"))
  let algorithm = method_from_json(required(f, "algorithm"))
  match operation {
    "rank" =>
      ranking_json(
        evaluate(m, json_numbers(required(f, "weights"), 32), algorithm),
      )
    "report" =>
      report_json(
        decision_report(m, json_numbers(required(f, "weights"), 32), algorithm),
      )
    "scenarios" => {
      let scenarios = json_array(required(f, "scenarios"), 64).map(row => {
        json_numbers(row, 32)
      })
      scenario_json(weight_scenarios(m, scenarios, algorithm))
    }
    _ => raise Invalid("operation must be rank, report or scenarios")
  }
}

///|
/// Portable string-in/string-out dispatcher. No filesystem, network or global state.
pub fn dispatch(request : String) -> String {
  let response = try {
    let result = execute_request(parse_document(request))
    Json::object({
      "schema": Json("moonchoice.response/1"),
      "ok": Json(true),
      "result": result,
    })
  } catch {
    Invalid(message) => error_response("invalid", message)
    Budget(message) => error_response("budget", message)
    Numerical(message) => error_response("numerical", message)
  }
  response.stringify()
}

///|
fn error_response(kind : String, message : String) -> Json {
  Json::object({
    "schema": Json("moonchoice.response/1"),
    "ok": Json(false),
    "error": Json::object({ "kind": Json(kind), "message": Json(message) }),
  })
}
