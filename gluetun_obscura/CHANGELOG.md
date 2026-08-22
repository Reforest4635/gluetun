# Changelog

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
