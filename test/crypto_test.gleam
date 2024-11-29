import birdie
import gleam/bit_array
import gleam/javascript/promise
import gleam/list
import gleam/uri
import glebs
import glebs/crypto
import glebs/request
import gleeunit/should
import pprint

pub fn get_random_values_test() {
  let data = <<0:size(256)>>
  crypto.get_random_values(data)
  |> should.be_ok
}

pub fn hash_test() {
  crypto.hash("hello")
  |> promise.tap(fn(hash) {
    hash
    |> should.be_ok
    |> bit_array.base64_encode(False)
    |> pprint.format
    |> birdie.snap(title: "hash")
  })
}

pub fn create_authorize_url_test() {
  let config =
    glebs.OAuth2ClientConfig(
      client_id: "client_id",
      authorize_url: "https://oauthserver.com/authorize",
      token_url: "https://oauthserver.com/token",
      redirect_uri: "https://example.com/redirect",
      scope: "scope",
    )

  request.create_authorization_request_url(config)
  |> promise.tap(fn(res) {
    let #(url, _verifier) = should.be_ok(res)

    url.path
    |> should.equal("/authorize")

    let params =
      url.query
      |> should.be_some
      |> uri.parse_query

    params
    |> should.be_ok
    |> list.each(fn(param) {
      case param {
        #("client_id", val) -> val |> should.equal(config.client_id)
        #("redirect_uri", val) -> val |> should.equal(config.redirect_uri)
        #("scope", val) -> val |> should.equal(config.scope)
        #("response_type", val) -> val |> should.equal("code")
        #("state", _) -> should.be_true(True)
        #("code_challenge_method", val) -> val |> should.equal("S256")
        #("code_challenge", _) -> should.be_true(True)
        _ -> should.be_true(False)
      }
    })
  })
}
