# Here we test various integration issues between the real world
# and code attempting to stick to rigorous functional programming.
# - external state changing (clock, config)
# - process being killed/restarted
# - server going down
# - connection interrupted
# - etc.

# We might also deal with real data ( like for recording cassettes )

# For this reason we do not want any mock here,
# each test manages their own environment setup,
# and are run synchronously.

# Overriding user's configuration for integration tests
# To prevent accidental authenticated calls to the server
# TODO : command line to prevent override,
# and use actual config, on demand (userful for recording cassettes)
Application.put_env(
  :xest_kraken,
  :config_file,
  Path.expand("./config.toml", Path.expand(__DIR__))
)

ExUnit.start()
