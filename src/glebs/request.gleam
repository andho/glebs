import decode/zero
import gleam/fetch
import gleam/fetch/form_data
import gleam/http/request
import gleam/javascript/promise
import gleam/result
import gleam/uri.{type Uri}
import glebs
import glebs/code

/// Create an authorization request url from the given config
///
/// You can redirect the user to the returned url to initiate the authorization
/// flow. Once authorization is complete, the user will be redirected back to
/// the redirect_uri in the config with the authorization code in the query
/// parameter.
///
/// You can then exchange the authorization code for an access token using the
/// `get_access_token` function.
pub fn create_authorization_request_url(
  config: glebs.OAuth2ClientConfig,
) -> promise.Promise(Result(#(Uri, String), String)) {
  use verifier <- promise.try_await(
    code.create_code_verifier()
    |> promise.resolve,
  )

  use code_challenge <- promise.try_await(code.get_code_challenge_from_verifier(
    verifier,
  ))

  let params = [
    #("client_id", config.client_id),
    #("redirect_uri", config.redirect_uri),
    #("scope", config.scope),
    #("response_type", "code"),
    #("state", "1234567890"),
    #("code_challenge_method", "S256"),
    #("code_challenge", code_challenge),
  ]

  config.authorize_url
  |> request.to
  |> result.map(fn(req) {
    req
    |> request.set_query(params)
    |> request.to_uri
  })
  |> result.replace_error("Cound not create authorization uri")
  |> result.map(fn(uri) { #(uri, verifier) })
  |> promise.resolve
}

fn token_resp_decoder() {
  use access_token <- zero.field("access_token", zero.string)
  use refresh_token <- zero.field("refresh_token", zero.string)
  use token_type <- zero.field("token_type", zero.string)
  use expires_in <- zero.field("expires_in", zero.int)

  zero.success(glebs.TokenResponse(
    access_token:,
    refresh_token:,
    token_type:,
    expires_in:,
  ))
}

pub fn get_access_token(
  config: glebs.OAuth2ClientConfig,
  verifier: String,
  code: String,
) {
  let _ = [
    #("client_id", config.client_id),
    #("grant_type", "authorization_code"),
    #("code", code),
    #("redirect_uri", config.redirect_uri),
    #("code_verifier", verifier),
  ]

  let req_body =
    form_data.new()
    |> form_data.set("client_id", config.client_id)
    |> form_data.set("grant_type", "authorization_code")
    |> form_data.set("code", code)
    |> form_data.set("redirect_uri", config.redirect_uri)
    |> form_data.set("code_verifier", verifier)

  use res <- promise.try_await(
    config.token_url
    |> request.to
    |> promise.resolve
    |> promise.await(fn(req_promise) {
      case req_promise {
        Ok(req) -> {
          req
          |> request.set_body(req_body)
          |> fetch.send_form_data
          |> promise.try_await(fetch.read_json_body)
          |> promise.map(fn(res_promise) {
            res_promise
            |> result.replace_error("Could not get access token")
          })
        }
        Error(_) -> {
          promise.resolve(Error("Could not create request"))
        }
      }
    }),
  )

  let decoder = token_resp_decoder()

  res.body
  |> zero.run(decoder)
  |> result.replace_error("Could not decode access token response")
  |> promise.resolve
}
