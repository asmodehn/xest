# XestCache

A Common Cache system specifically for Xest usecase:
- function based (**idempotent** real world effects)
- in memory
- with ttl
- used for caching some (explicitly specified) responses to web requests
- with different setting based on client code.

So XestCache aims to be an adaptive reverse proxy for BEAM-based client code.

## Rough Roadmap:

1. Nebulex wrapper
2. Custom implementation (see Xest.TransientMap) behind wrapper
3. Configurable with unified interface between Nebulex and Custom Xest implementation
4. Allow possibility of customizing clock (leverage xest_clock there) in both implementations.
4. Adaptative settings for custom implementation...
Use control theory to dynamically adjust settings ( the ones from the nebulex config) depending on network behaviour.

