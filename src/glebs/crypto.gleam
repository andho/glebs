import gleam/bit_array
import gleam/javascript/promise.{type Promise}
import gleam/result
import gleam/string

@external(javascript, "../glebs_crypto_ffi.mjs", "getRandomValues")
fn do_get_random_values(data: BitArray) -> Result(BitArray, String)

pub fn get_random_values(data) {
  do_get_random_values(data)
}

pub fn get_random_string(length: Int) -> Result(String, String) {
  let data = <<0:size({ length * 8 })>>
  get_random_values(data)
  |> result.map(bits_to_string)
}

fn bits_to_string(bits: BitArray) {
  bits
  |> bit_array.base16_encode
  |> string.lowercase
}

@external(javascript, "../glebs_crypto_ffi.mjs", "hash")
fn do_hash(data: String) -> Promise(Result(BitArray, String))

pub fn hash(data) {
  do_hash(data)
}
