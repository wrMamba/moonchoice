///|
/// Bounded parse: at most 1 Mi code units, with at most eight nested containers.
pub fn parse_document(text : String) -> Json raise ChoiceError {
  if text.length() > 1048576 {
    raise Budget("JSON document exceeds 1 Mi code units")
  }
  let mut depth = 0
  let mut in_string = false
  let mut escaped = false
  for c in text.iter() {
    if in_string {
      if escaped {
        escaped = false
      } else if c == '\\' {
        escaped = true
      } else if c == '"' {
        in_string = false
      }
    } else if c == '"' {
      in_string = true
    } else if c == '[' || c == '{' {
      depth += 1
      if depth > 8 {
        raise Budget("JSON nesting exceeds eight containers")
      }
    } else if c == ']' || c == '}' {
      depth -= 1
    }
  }
  @json.parse(text[:]) catch {
    _ => raise Invalid("invalid JSON or excessive nesting")
  }
}

///|
fn object_fields(
  value : Json,
  allowed : Array[String],
) -> Map[String, Json] raise ChoiceError {
  guard value is Object(fields) else { raise Invalid("expected a JSON object") }
  for key, _ in fields {
    if !allowed.contains(key) {
      raise Invalid("unknown JSON field: " + key)
    }
  }
  fields
}

///|
fn required(fields : Map[String, Json], key : String) -> Json raise ChoiceError {
  match fields.get(key) {
    Some(value) => value
    None => raise Invalid("missing JSON field: " + key)
  }
}

///|
fn json_string(value : Json) -> String raise ChoiceError {
  guard value is String(s) else { raise Invalid("expected JSON string") }
  s
}

///|
fn json_number(value : Json) -> Double raise ChoiceError {
  guard value is Number(x, ..) else { raise Invalid("expected JSON number") }
  input_number(x)
  x
}

///|
fn json_array(value : Json, limit : Int32) -> Array[Json] raise ChoiceError {
  guard value is Array(items) else { raise Invalid("expected JSON array") }
  if items.length() > limit {
    raise Budget("JSON array exceeds supported length")
  }
  items
}

///|
fn json_numbers(value : Json, limit : Int32) -> Array[Double] raise ChoiceError {
  json_array(value, limit).map(json_number)
}

///|
fn matrix_from_json(value : Json) -> DecisionMatrix raise ChoiceError {
  let f = object_fields(value, [
    "schema", "alternatives", "criteria", "directions", "values",
  ])
  if json_string(required(f, "schema")) != "moonchoice.matrix/1" {
    raise Invalid("unsupported matrix schema")
  }
  let names = json_array(required(f, "alternatives"), 256).map(json_string)
  let criteria = json_array(required(f, "criteria"), 32).map(json_string)
  let directions = json_array(required(f, "directions"), 32).map(v => {
    match json_string(v) {
      "benefit" => Benefit
      "cost" => Cost
      _ => raise Invalid("direction must be benefit or cost")
    }
  })
  let values = json_array(required(f, "values"), 256).map(row => {
    json_numbers(row, 32)
  })
  decision_matrix(names, criteria, directions, values)
}

///|
pub fn decode_matrix(text : String) -> DecisionMatrix raise ChoiceError {
  matrix_from_json(parse_document(text))
}

///|
pub fn DecisionMatrix::to_json(self : DecisionMatrix) -> Json {
  Json::object({
    "schema": Json::string("moonchoice.matrix/1"),
    "alternatives": Json(self.names),
    "criteria": Json(self.criteria),
    "directions": Json(
      self.directions.map(d => if d == Benefit { "benefit" } else { "cost" }),
    ),
    "values": Json(self.cells),
  })
}

///|
pub fn encode_matrix(m : DecisionMatrix) -> String {
  m.to_json().stringify()
}

///|
/// Validates externally mutable Ranking arrays before serializing them.
pub fn ranking_json(ranking : Ranking) -> Json raise ChoiceError {
  let r = validated_ranking(ranking)
  Json::object({
    "schema": Json::string("moonchoice.ranking/1"),
    "labels": Json(r.labels),
    "scores": Json(r.scores),
    "order": Json(r.order),
    "ranks": Json(r.ranks),
    "higher_is_better": Json(r.higher_is_better),
    "tie_tolerance": Json(r.tie_tolerance),
    "winners": Json(r.winners()),
  })
}
