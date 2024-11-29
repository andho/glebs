FROM erlang:27

RUN curl https://s3.amazonaws.com/rebar3/rebar3 -o ./rebar3
RUN erl ./rebar3 local install
RUN rm ./rebar3

RUN mkdir -p /opt/gleam/bin
WORKDIR /opt/gleam/bin
RUN curl -sL https://github.com/gleam-lang/gleam/releases/download/v1.6.2/gleam-v1.6.2-x86_64-unknown-linux-musl.tar.gz -o ./gleam.tar.gz
RUN tar -zxvf ./gleam.tar.gz
RUN rm ./gleam.tar.gz
ENV PATH="/opt/gleam/bin:${PATH}:/root/.cache/rebar3/bin"

RUN apt-get update && apt-get install -y inotify-tools

WORKDIR /app
#COPY . .
#RUN gleam deps download
