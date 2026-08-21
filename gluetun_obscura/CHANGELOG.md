# Changelog

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
