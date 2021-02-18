# Xest

Xest connects to various cryptocurrencies exchanges.

On each exchange, it publically retrieves:
  - Exchange status and time
  - market tickers (WIP)
In your wallet, it privately retrieves:
  - retrieves currencies (WIP)
  - visually display your assets (WIP)

# Running

```
mix phx.server
```

# Testing

```
mix test
```

For a TDD setup, you can use
```
mix test.watch
```

For coverage you can use
```
mix coveralls
```

For code analysis you can use
```
mix credo
```

# Dev
This is an Elixir Umbrella project, trying to remain monorepo as long as possible.

Currently there are only two apps here:
  - Xest: the client connecting to the crypto exchanges
  - XestWeb: the Web interface




