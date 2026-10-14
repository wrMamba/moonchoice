///|
/// RFC-style quoting without delimiter guessing; CRLF and LF record endings.
fn csv_records(text : String) -> Array[Array[String]] raise ChoiceError {
  if text.length() > 1048576 { raise Budget("CSV exceeds 1 Mi code units") }
  let chars = text.to_array()
  let records : Array[Array[String]] = []
  let mut row : Array[String] = []
  let field = StringBuilder()
  let mut quoted = false
  let mut closed = false
  let mut started = false
  let mut i = 0
  while i < chars.length() {
    let c = chars[i]
    if quoted {
      if c == '"' {
        if i + 1 < chars.length() && chars[i + 1] == '"' {
          field.write_char('"')
          i += 1
        } else { quoted = false; closed = true }
      } else { field.write_char(c) }
    } else if c == ',' || c == '\n' || c == '\r' {
      row.push(field.to_string())
      if row.length() > 33 { raise Budget("CSV record exceeds 33 fields") }
      field.reset()
      started = false
      closed = false
      if c != ',' {
        records.push(row)
        if records.length() > 258 { raise Budget("CSV exceeds 258 records") }
        row = []
        if c == '\r' {
          if i + 1 >= chars.length() || chars[i + 1] != '\n' {
            raise Invalid("unquoted CR must be followed by LF")
          }
          i += 1
        }
      }
    } else {
      if closed { raise Invalid("unexpected character after closing CSV quote") }
      if c == '"' {
        if started { raise Invalid("CSV quote must start a field") }
        quoted = true
        started = true
      } else {
        started = true
        field.write_char(c)
      }
    }
    if field.to_string().length() > 4096 { raise Budget("CSV field exceeds 4096 code units") }
    i += 1
  }
  if quoted { raise Invalid("unterminated CSV quoted field") }
  if started || closed || row.length() > 0 {
    row.push(field.to_string())
    if row.length() > 33 { raise Budget("CSV record exceeds 33 fields") }
    records.push(row)
  }
  if records.length() > 258 { raise Budget("CSV exceeds 258 records") }
  records
}

///|
/// Header alternative,<criteria>; second record direction,<benefit|cost>.
pub fn decode_csv(text : String) -> DecisionMatrix raise ChoiceError {
  let records = csv_records(text)
  if records.length() < 3 { raise Invalid("CSV requires headers, directions and alternatives") }
  let header = records[0]
  let directions_row = records[1]
  if header.length() < 2 || header[0] != "alternative" {
    raise Invalid("CSV first header must be alternative")
  }
  if directions_row.length() != header.length() || directions_row[0] != "direction" {
    raise Invalid("CSV direction record has wrong shape or marker")
  }
  let criteria = [ for j in 1..<header.length() => header[j] ]
  let directions = [ for j in 1..<header.length() => {
    match directions_row[j] {
      "benefit" => Benefit
      "cost" => Cost
      _ => raise Invalid("CSV direction must be benefit or cost")
    }
  } ]
  let names : Array[String] = []
  let values : Array[Array[Double]] = []
  for i in 2..<records.length() {
    let row = records[i]
    if row.length() != header.length() { raise Invalid("CSV record width mismatch") }
    names.push(row[0])
    values.push([ for j in 1..<row.length() => {
      let value = row[j].trim().to_owned()
      if value.length() == 0 { raise Invalid("empty numeric CSV field") }
      json_number(parse_document(value))
    } ])
  }
  decision_matrix(names, criteria, directions, values)
}

///|
fn csv_field(text : String) -> String {
  if text.contains_char(',') || text.contains_char('"') || text.contains_char('\n') || text.contains_char('\r') {
    "\"" + text.replace_all(old="\"", new="\"\"") + "\""
  } else { text }
}

///|
fn csv_line(fields : Array[String]) -> String {
  let builder = StringBuilder()
  for i, field in fields {
    if i > 0 { builder.write_char(',') }
    builder.write_string(csv_field(field))
  }
  builder.write_string("\r\n")
  builder.to_string()
}

///|
pub fn encode_csv(m : DecisionMatrix) -> String {
  let builder = StringBuilder()
  let header = ["alternative"]
  for name in m.criteria { header.push(name) }
  builder.write_string(csv_line(header))
  let directions = ["direction"]
  for d in m.directions { directions.push(if d == Benefit { "benefit" } else { "cost" }) }
  builder.write_string(csv_line(directions))
  for i, name in m.names {
    let row = [name]
    for value in m.cells[i] { row.push(value.to_json().stringify()) }
    builder.write_string(csv_line(row))
  }
  builder.to_string()
}
