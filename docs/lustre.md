# Integrating with Lustre

## Configuration

Integration with Lustre is simple. To begin, you need to have the config
available in your applications model. For the purpose of this example we will
just create the config in init:

```gleam
pub type Model {
  Model(
    config: glebs.OAuth2ClientConfig,
    token: option.Option(glebs.TokenResponse),
  )
}

pub fn init(config: Config) -> #(Model, effect.Effect(Msg)) {
  let config =
    glebs.OAuth2ClientConfig(
      client_id: config.client_id,
      authorize_url: config.authorize_url,
      token_url: config.token_url,
      redirect_uri: config.redirect_uri,
      scope: config.scope,
    )

  #(
    Model(
      config: config,
      token: option.None,
    ),
    handle_auth_code(config),
  )
```

The `handle_auth_code` function is used to later handle the redirect. If you're
using `modem` this part can be nicer, but for this example we'll just check on
init. Handling the redirect will be explained later though.

## Redirect the user to the authorization url

Define a function that will get the authorization url and redirect the user.
`plinth/browser/window` is used to do the redirect.

```gleam
fn login(config: glebs.OAuth2ClientConfig) -> effect.Effect(Msg) {
  effect.from(fn(_) {
    glebs_request.create_authorization_request_url(config)
    |> promise.map_try(fn(authorize_url) {
      let curr_window = window.self()

      let _ =
        storage.local()
        |> result.map(storage.set_item(_, "glebs_verifier", authorize_url.1))

      let curr_window = window.self()
      window.set_location(curr_window, uri.to_string(authorize_url.0))

      Ok(Nil)
    })

    Nil
  })
}
```

This is basically same as the example code in the [README](../README.md) but
using lustre's `effect`, although there is no effect dispatched because the
browser will be redirected to another webside.

You can trigger this function from your `update` function based on some Msg.

## Handling the redirect

Once the user is redirected back to the redirect_uri, you'll have to get the
`code` from the query parameter and use it to exchange the authorization code
for an access token.

As mentioned before, during `init` we fire off an effect `handle_auth_code`.
Let's take a look at the implementation:

```gleam
fn handle_auth_code(config: glebs.OAuth2ClientConfig) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    window.location()
    |> uri.parse
    |> result.try(fn(current_uri) {
      case uri.path_segments(current_uri.path) {
        ["oauth", "handle"] -> {
          case current_uri.query {
            Some(query) -> uri.parse_query(query)
            None -> Error(Nil)
          }
        }
        _ -> Error(Nil)
      }
    })
    |> result.map(dict.from_list)
    |> result.try(dict.get(_, "code"))
    |> result.map(try_get_access_token(_, config, dispatch))

    Nil
  })
}
```

We check if the current url is `/oauth/handle` and if so, we parse the query
parameter and get the `code` from it. We then pass the code to
`try_get_access_token` function to get the access token.

`try_get_access_token` function takes the config, the authorization code and the
dispatch function as input and calls dispatch the `LoggedInSuccessfully` Msg
with the access token if the request was successful.

```gleam
fn try_get_access_token(
  code: String,
  config: glebs.OAuth2ClientConfig,
  dispatch: fn(Msg) -> Nil,
) -> Nil {
  // grab the from local storage
  storage.local()
  |> promise.resolve
  |> promise.map_try(storage.get_item(_, "glebs_verifier"))
  |> promise.map(result.replace_error(_, "Couldn't get verifier from storage"))
  |> promise.try_await(fn(verifier) {
    glebs_request.get_access_token(config, verifier, code)
    |> promise.map(fn(token) {
      case token {
        Ok(token) -> {
          dispatch(LoggedInSuccessfully(token))
          Ok(Nil)
        }
        Error(error) -> {
          Ok(Nil)
        }
      }
    })
    |> promise.rescue(fn(_) {
      Ok(Nil)
    })
  })

  Nil
}
```

The `glebs_request.get_access_token` function takes the config, the code verifier
and the authorization code as input and returns an
`Promise(Result(glebs.TokenResponse), String)` if the request was successful.

**Note:** Bad error handling.

One the access token is received, we dispatch the `LoggedInSuccessfully` Msg.
Now you can store it in your model and use it to make requests to the API.
