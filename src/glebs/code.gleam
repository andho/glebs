import gleam/bit_array
import gleam/javascript/promise
import gleam/result
import glebs/crypto

pub fn create_code_verifier() {
  crypto.get_random_string(32)
}

pub fn get_code_challenge_from_verifier(verifier: String) {
  crypto.hash(verifier)
  |> promise.map(fn(res) {
    res
    |> result.map(bit_array.base64_encode(_, False))
  })
}
