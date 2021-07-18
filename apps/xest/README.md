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
