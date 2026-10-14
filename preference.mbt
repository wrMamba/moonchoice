///|
pub(all) enum Preference {
  Usual
  UShape(Double)
  VShape(Double)
  Level(Double, Double)
  Linear(Double, Double)
  Gaussian(Double)
} derive(Debug)

///|
fn valid_preference(pref : Preference) -> Unit raise ChoiceError {
  match pref {
    Usual => ()
    UShape(q) => {
      input_number(q)
      if q < 0.0 { raise Invalid("indifference threshold must be nonnegative") }
    }
    VShape(p) | Gaussian(p) => {
      input_number(p)
      if p <= 0.0 { raise Invalid("preference scale must be positive") }
    }
    Level(q, p) | Linear(q, p) => {
      input_number(q)
      input_number(p)
      if q < 0.0 || p <= q { raise Invalid("thresholds must satisfy 0 <= q < p") }
    }
  }
}

///|
fn preference_unchecked(pref : Preference, difference : Double) -> Double {
  if difference <= 0.0 { return 0.0 }
  match pref {
    Usual => 1.0
    UShape(q) => if difference <= q { 0.0 } else { 1.0 }
    VShape(p) => if difference >= p { 1.0 } else { difference / p }
    Level(q, p) => if difference <= q { 0.0 } else if difference <= p { 0.5 } else { 1.0 }
    Linear(q, p) => if difference <= q { 0.0 } else if difference >= p { 1.0 } else { (difference - q) / (p - q) }
    Gaussian(s) => {
      let ratio = difference / s
      // Avoid squaring a huge ratio and improve accuracy near zero.
      if ratio >= 40.0 { 1.0 } else { -@math.expm1(-0.5 * ratio * ratio) }
    }
  }
}

///|
pub fn preference_degree(pref : Preference, difference : Double) -> Double raise ChoiceError {
  valid_preference(pref)
  input_number(difference)
  preference_unchecked(pref, difference)
}
