# Xest

Here we gather the various exchanges local representations

Curently only for Binance.

Our runtime has two processes
- A GenServer holding the Binance Client
- An Agent managing the Exchange state (status and servertime)

For code design we follow a loose DDD-like architecture, simplified given elixir strength:
- domain models holding state, providing read and update functions
- ports specifying interface for external systems (such as an HTTP client)
- adapters providing implementations for these ports (specified in the application config)

For usage:
- Clients should use the interface from the Agents and GenServers to benefit from runtime management features.
- **TODO** Services are available if a user who doesnt want/need the runtime capabilities 
- Ports/Adapters are also directly usable, if any user want to bypass all domain logic in here
