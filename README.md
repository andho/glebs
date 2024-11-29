# glebs

[![Package Version](https://img.shields.io/hexpm/v/glebs)](https://hex.pm/packages/glebs)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glebs/)

```sh
gleam add glebs@1
```

Get an authorization url based on the config and redirect the user to the url:

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

Further documentation can be found at <https://hexdocs.pm/glebs>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
