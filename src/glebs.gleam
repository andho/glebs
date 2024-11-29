import gleam/io

pub type OAuth2ClientConfig {
  OAuth2ClientConfig(
    client_id: String,
    authorize_url: String,
    token_url: String,
    redirect_uri: String,
    scope: String,
  )
}

pub type TokenResponse {
  TokenResponse(
    access_token: String,
    token_type: String,
    expires_in: Int,
    refresh_token: String,
  )
}

pub fn main() {
  io.println("Hello from glebs!")
}
