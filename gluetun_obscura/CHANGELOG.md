# Changelog

## 1.0.4
- Added `dot_enabled`, `block_malicious`, `block_ads`, and
  `block_surveillance` options. Previously none of these were exposed, so
  Gluetun ran on its own defaults - and `BLOCK_MALICIOUS` defaults to ON.
  Gluetun's blocklists refresh on a timer and can start blackholing
  BitTorrent tracker domains with no config change on our side, which
  presents as trackers that worked yesterday failing to resolve today
  (blackhole answers like `10.255.255.254`, or SERVFAIL). All three
  blocklists now default to OFF.
- Fix: `dns_servers` left blank in the Configuration tab was exported as an
  empty `DNS_ADDRESS`, causing Gluetun to silently fall back to the DNS
  server advertised by the VPN tunnel instead of the configured upstream.
  Symptom: HTTP proxy log lines reading `lookup <host> on 10.64.0.1:53:
  server misbehaving` - an address that appears nowhere in the add-on
  config. Blank now defaults to 1.1.1.1.
- The resolved DNS settings (upstream, DoT state, all three blocklists) are
  now logged at startup so the active configuration is visible in the
  add-on log rather than having to be inferred.
- Note: when `dot_enabled` is on, Gluetun uses its own DoT provider list
  and `dns_servers` is ignored.

## 1.0.3
- Fix: HA Supervisor injects its own internal DNS resolver into every
  add-on's `/etc/resolv.conf`, which overrode Gluetun's own DNS handling.
  Symptom: HTTP proxy log showed `dial tcp 172.30.32.1:80: connection
  refused` for external hostnames (e.g. tracker.openbittorrent.com) -
  172.30.32.1 is Supervisor's internal DNS/gateway address, not a real
  public IP, meaning lookups were resolving to the wrong place entirely.
  Fix forces the container to use Gluetun's own loopback resolver
  (127.0.0.1) instead. Matches a documented upstream Gluetun issue with the
  same symptom caused by other external DNS overrides (e.g. AdGuard Home).

## 1.0.2
- Fix: docs and config.yaml incorrectly called port 8388 "SOCKS5". It's
  actually Gluetun's Shadowsocks proxy, a different (encrypted) protocol
  that plain SOCKS5 clients like qBittorrent's built-in proxy option can't
  speak to. Symptom was `[shadowsocks] ... reading target address:
  unexpected EOF` in the Gluetun log.
- Added `shadowsocks_password` option (only relevant if you set up a
  Shadowsocks-aware client, e.g. an `sslocal` bridge for full SOCKS5+UDP
  support).
- DOCS.md now recommends the HTTP proxy (8888) for apps that only speak
  plain HTTP/SOCKS5, with the UDP/DHT tunneling trade-off called out.

## 1.0.1
- Fix: replaced invalid `cap_add` config.yaml key with the correct HA add-on
  `privileged: [NET_ADMIN]` key. `cap_add` isn't part of the add-on config
  schema and was silently ignored, so gluetun never actually got NET_ADMIN
  and iptables failed with "Permission denied (you must be root)".

## 1.0.0
- Initial release: Gluetun wrapped as an HA add-on, configured for Obscura
  VPN via WireGuard custom-provider fields.
- Exposes HTTP proxy (8888), SOCKS5 proxy (8388 tcp/udp), and control
  server (8000).
