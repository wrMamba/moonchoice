///|
test "JSON service executes reports and returns stable errors" {
  let request = Json::object({
    "schema": Json("moonchoice.request/1"),
    "operation": Json("report"),
    "matrix": sample().to_json(),
    "weights": Json([0.5, 0.5]),
    "algorithm": Json::object({
      "kind": Json("topsis"),
      "normalization": Json("minmax"),
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
