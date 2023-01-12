# Xest

Here we gather the various exchanges local representations

Our runtime has two processes
- An Agent managing the Exchange state (status and servertime)
- An Agent managing the account state (balance, etc.). This requires authentication.

Our code structure has 4 levels of (dependent) abstractions:
- Application Interface ( Web, later Scenic, maybe more...)
- Common Xest abstractions over various backend
- Exchange/Account (Agent to hold the know state of the remote exchange server)
- Adapter (Module dependent on HTTP library structure)

Timewise, the Adapter will poll to retrieve information and attempt to maintain the Agent state.
A cache is in place to avoid spamming servers. Later websockets could be used as well.
The Agent is there to keep a memory of the past events and expose current state.
The common Xest structures can extrapolate from past events to estimate current situation, where reasonably safe...


## Next Step

After some time, xest has grown into both conflicting conceptual apps/libs:
- one that is used as the interface to concrete connector implementation (kraken and binance) with behaviours, protocols, etc.
- one that is used as the "logical backend" for the web UI (and maybe more later)

This is problematic as:
- the web (and xest app) wants to make sure all connector implementations work as expected...
- connector implementations depend on xest to know how to communicate with the rest of the software.

There are conflicts in dependencies (although in an umbrella app, these might not be obvious at first),
but when changing some xest modules used everywhere, sometimes, only part of them are rebuilt by mix.

There are also likely other hidden conflicts brought by this current state of things.
At a high level, this resemble a Strategy Pattern, and we should therefore separate those two concerns in two apps/libs.

Proposed solution:
- a xest_connector lib, containing all modules necessary to build a working interface to a crypto exchange API.
- a xest app as it is now, only to be the client of these connectors (via an adapter, token with protocols, or some other convenient elixir design),
  and the unique contact point from the web (and other UI apps).