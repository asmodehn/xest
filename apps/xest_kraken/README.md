# XestKraken

![mermaid rendered diagram](https://mermaid.ink/svg/eyJjb2RlIjoiZ3JhcGggVERcbiAgICBBW1hlc3RdIC0tPiB8cHVibGljfCBCKEV4Y2hhbmdlKVxuICAgIEEgLS0-IHxwcml2YXRlfCBDKEFjY291bnQpXG4gICAgXG4gICAgQiAtLT4gfHRocm90dGxlZHwgRHtBZGFwdGVyfVxuICAgIEMgLS0-IHx0aHJvdHRsZWR8IERcblxuICAgIEQgLS0-IHxBUEkgcmVxdWVzdHwgRVtLcmFrZXhdXG4iLCJtZXJtYWlkIjp7InRoZW1lIjoiZGVmYXVsdCJ9LCJ1cGRhdGVFZGl0b3IiOmZhbHNlfQ)

```mermaid
graph TD
    A[Xest] --> |public| B(Exchange)
    A --> |private| C(Account)
    
    B --> |throttled| D{Adapter}
    C --> |throttled| D

    D --> |API request| E[Krakex]
```

