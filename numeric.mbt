///|
pub suberror ChoiceError {
  Invalid(String)
  Budget(String)
  Numerical(String)
} derive(Debug)

///|
fn finite(x : Double) -> Bool {
  x == x && x.abs() <= 1.0e300
}

///|
fn checked(x : Double) -> Double raise ChoiceError {
  if !finite(x) {
    raise Numerical("non-finite or excessively large intermediate")
  }
  x
}

///|
fn input_number(x : Double) -> Unit raise ChoiceError {
  if !finite(x) || x.abs() > 1.0e100 {
    raise Invalid("numeric inputs must be finite and bounded by 1e100")
  }
}

///|
fn probability(x : Double) -> Unit raise ChoiceError {
  if !finite(x) || x < 0.0 || x > 1.0 {
    raise Invalid("parameter must be in 0..1")
  }
}

///|
fn valid_tolerance(t : Double) -> Unit raise ChoiceError {
  if !finite(t) || t < 0.0 || t > 0.01 {
    raise Invalid("absolute tie tolerance must be in 0..0.01")
  }
}

///|
fn zeros(n : Int, p : Int) -> Array[Array[Double]] {
  [ for _ in 0..<n => Array::make(p, 0.0) ]
}

///|
fn maximum(x : Array[Double]) -> Double {
  let mut best = x[0]
  for v in x {
    if v > best {
      best = v
    }
  }
  best
}

///|
fn minimum(x : Array[Double]) -> Double {
  let mut best = x[0]
  for v in x {
    if v < best {
      best = v
    }
  }
  best
}

///|
fn sum(x : Array[Double]) -> Double {
  // Neumaier compensated summation for mixed-sign preference flows.
  let mut total = 0.0
  let mut correction = 0.0
  for value in x {
    let next = total + value
    correction += if total.abs() >= value.abs() {
      (total - next) + value
    } else {
      (value - next) + total
    }
    total = next
  }
  total + correction
}
