use Mix.Config

config :phoenix, :json_library, Jason

config :origami, Origami.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  check_origin: false,
  secret_key_base: "TESTKEYBASE",
  pubsub_server: Origami.PubSub
