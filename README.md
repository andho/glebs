# glebs

[![Package Version](https://img.shields.io/hexpm/v/glebs)](https://hex.pm/packages/glebs)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glebs/)

```sh
gleam add glebs
```

Glebs is an OAuth PKCE helper for Gleam in Browser. You can easily use this with
lustre, see [lustre integration](docs/lustre.md) for more information.

## Usage

### Create an OAuth2ClientConfig

```gleam
import glebs

let config =
  glebs.OAuth2ClientConfig(
    client_id: "12345",
    authorize_url: "https://oauthserverexample.com/authorize",
    token_url: "https://oauthserverexample.com/token",
    redirect_uri: "https://example.com/redirect",
    scope: "",
  )
```

You would usually set the config values during build time, or allow user to
specify the configuration and store it in local storage.

### Get an authorization url and redirect the user

Using the config get an authorization url based on the config and redirect the
user to the url:

```gleam
import glebs/request
import gleam/javascript/promise
import plinth/browser/window

request.create_authorization_request_url(config)
|> promise.map_try(fn(authorize_url) {
  let curr_window = window.self()

  let _ =
    storage.local()
    |> result.map(storage.set_item(_, "glebs_verifier", authorize_url.1))

  let curr_window = window.self()
  window.set_location(curr_window, uri.to_string(authorize_url.0))

  Ok(Nil)
})
```

The `request.create_authorization_request_url` function returns a tuple of
`#(Uri, String)` where the first element is the authorization url and the second
element is the code verifier. You should store the code verifier in session
storage to be able to exchange the authorization code for an access token.

### Exchange the authorization code for an access token

```gleam
import glebs/request
import gleam/javascript/promise

request.get_access_token(config, verifier, code)
|> promise.map(fn(res) {
  case res {
    Ok(token) -> {
      // Do something with the token
    }
    Error(err) -> {
      // Handle error
    }
  }
})
```

The `request.get_access_token` function takes the config, the code verifier and
the authorization code as input and returns an
`Promise(Result(glebs.TokenResponse), String)` if the request was successful.

Further documentation can be found at <https://hexdocs.pm/glebs>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## Todo

- [ ] Get new token from refresh token if token has expired
- [ ] Add better error handling
