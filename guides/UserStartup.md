# Xest User Startup


## Web Usage

Run the webapp

```
iex -S mix phx.server
```

And now you can access:

- http://localhost:4000/kraken
- http://localhost:4000/binance


## Interactive Usage

Run the app

```
iex -S mix
```

And now you can directly access information:

- Exchange
  ```
  iex(*)> XestBinance.Exchange.status()
  ```
- Account
  ```
  iex(*)> XestBinance.Account.balance(XestBinance.Account
  ```