///|
test "JSON service executes reports and returns stable errors" {
  let request = Json::object({
    "schema": "moonchoice.request/1".to_json(),
    "operation": "report".to_json(),
    "matrix": sample().to_json(),
    "weights": [0.5, 0.5].to_json(),
    "algorithm": Json::object({
      "kind": "topsis".to_json(),
      "normalization": "minmax".to_json(),
    }),
  })
  let response = object_fields(parse_document(dispatch(request.stringify())), [
    "schema", "ok", "result",
  ])
  assert_true(required(response, "ok") is True)
  let error = object_fields(parse_document(dispatch("invalid")), [
    "schema", "ok", "error",
  ])
  assert_true(required(error, "ok") is False)
  for
    invalid in [
      "{\"kind\":\"saw\"}", "{\"kind\":\"product\",\"v\":0.5}", "{\"kind\":\"vikor\",\"v\":2}",
    ] {
    try method_from_json(parse_document(invalid)) catch {
      _ => ()
    } noraise {
      _ => fail("invalid method accepted")
    }
  }
}
