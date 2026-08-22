# Gluetun (Obscura VPN)

Routes traffic through Obscura VPN via Gluetun's built-in proxies, so your
*arr suite add-ons (Prowlarr indexer searches, download clients, etc.) can be
pointed at a proxy without needing to be re-platformed off Home Assistant
add-ons.

## Why a proxy, not full container tunneling

Home Assistant's Supervisor doesn't expose a way to put one add-on's
container inside another add-on's network namespace (the
`network_mode: service:gluetun` trick from plain docker-compose isn't
available here). So this add-on can't transparently "wrap" your other
add-ons' entire network stack. Instead, Gluetun exposes two proxy servers,
and you point specific traffic at them from within each *arr app's own proxy
settings. This is the same approach used by the community Gluetun add-ons
for HA OS.

## The two proxy types are not interchangeable

This is the part that trips people up, so read carefully:

- **HTTP proxy (port 8888)** - a standard HTTP/HTTPS proxy, including
  CONNECT-based tunneling for arbitrary TCP. Any app with a plain "HTTP
  proxy" setting works with this directly.
- **Shadowsocks proxy (port 8388)** - despite the name similarity, this is
  **not** plain SOCKS5. Shadowsocks is a SOCKS5-based protocol with its own
  encryption layer, and it needs a Shadowsocks-aware client. Pointing a
  normal SOCKS5 client (e.g. qBittorrent's built-in "SOCKS5" proxy type) at
  this port will fail - you'll see `reading target address: unexpected EOF`
  in the Gluetun log, because the plain SOCKS5 handshake isn't something the
  Shadowsocks server understands.

**Gluetun does not expose a plain, unauthenticated SOCKS5 proxy out of the
box.** For qBittorrent (or any app that only speaks plain SOCKS5, not
Shadowsocks), use the **HTTP proxy (8888)** instead. Set the proxy type to
HTTP in qBittorrent's Connection settings, keep "Use proxy for peer
connections" checked, and be aware of one trade-off: HTTP proxies only
tunnel TCP, not UDP - so UDP-based DHT and uTP peer traffic won't route
through the tunnel via this method. If you want every protocol (including
UDP) fully tunneled, run a local Shadowsocks client (`sslocal`, e.g. as a
sidecar/local add-on) pointed at Gluetun's Shadowsocks server; it exposes a
real SOCKS5 proxy that qBittorrent can then use, with everything actually
riding on the encrypted Shadowsocks link underneath. Ask if you want this
add-on scaffolded too.

## Step 1: Get your Obscura WireGuard config

Gluetun doesn't have Obscura as a native provider, but Obscura's WireGuard
compatibility mode exports a config that works with Gluetun's `custom`
provider:

1. Log into your Obscura account portal.
2. Go to **Manage WireGuard configs** → **Active Tunnels** → **Register
   WireGuard config**.
3. Choose a Relay Server location (and optionally an Exit Server).
4. Click **Generate config**, then download the `.conf` file.

Note: WireGuard compatibility mode uses the standard WireGuard protocol, not
Obscura's QUIC-based obfuscation - fine for routing *arr traffic, just be
aware it's the plain WireGuard tunnel, not their stealth protocol.

Open the downloaded `.conf` file - it looks like:

```
[Interface]
PrivateKey = <your private key>
Address = 10.x.x.x/32

[Peer]
PublicKey = <server public key>
Endpoint = <server ip>:<port>
AllowedIPs = 0.0.0.0/0
```

Map those into the add-on options:

| Add-on option              | From the `.conf` file      |
|-----------------------------|-----------------------------|
| `wireguard_private_key`     | `PrivateKey`                |
| `wireguard_addresses`       | `Address`                   |
| `wireguard_public_key`      | `PublicKey` (under `[Peer]`)|
| `wireguard_endpoint_ip`     | `Endpoint`, the IP part     |
| `wireguard_endpoint_port`   | `Endpoint`, the port part   |

## Step 2: Install the add-on

1. Settings → Add-ons → Add-on Store → ⋮ → Repositories → add this repo's
   URL.
2. Find "Gluetun (Obscura VPN)" and install.
3. Fill in the Configuration tab with the values from Step 1.
4. Start the add-on and check the log for a successful tunnel connection.
   You should see a line confirming the public IP has changed to Obscura's
   relay server.

## Step 3: Point your *arr apps at the proxy

The exact screen depends on the app, but the pattern is the same:

- **Prowlarr**: Settings → Indexers → Indexer Proxies → add a new proxy
  (type HTTP, host = the Gluetun add-on's hostname/IP on your HA host,
  port 8888), give it a tag. Then edit each indexer you want tunneled and
  apply that tag under its proxy setting. Note: FlareSolverr-tagged indexers
  route through FlareSolverr's own outbound connection, not this proxy - see
  the FlareSolverr note below.
- **Radarr / Sonarr / Lidarr**: Settings → General → proxy section, type
  HTTP, host = Gluetun's address, port 8888.
- **Download client (qBittorrent, etc.)**: use proxy type **HTTP**, port
  8888 - not SOCKS5/8388, see the protocol note above.
- **FlareSolverr**: routes its own browser traffic separately from
  everything above. If your FlareSolverr add-on exposes a `PROXY_URL` (or
  similarly named) config option, set it to `http://<gluetun-host>:8888` to
  tunnel it too. Some community FlareSolverr add-ons don't expose this
  option.

Use the Gluetun add-on's local hostname (typically
`<addon-hostname>` shown on the add-on's Info tab, or the HA host's IP) and
port `8888` for HTTP, or `8388` for SOCKS5.

## Verifying the tunnel

Hit the control server for status (only works if you set
`control_server_api_key`):

```
curl -H "X-Api-Key: <your key>" http://<addon-host>:8000/v1/publicip/ip
```

Or check the add-on log on startup - Gluetun logs the public IP it's
tunneling through once connected.

## Kill switch

Gluetun's firewall blocks outbound traffic by default if the VPN tunnel
drops, so the proxy simply stops responding rather than leaking traffic
outside the tunnel - no extra config needed for that.

## Notes

- `wireguard_preshared_key` and `firewall_outbound_subnets` are optional;
  leave blank/empty unless you need them.
- The Docker image tag is pinned in the Dockerfile. Bump it deliberately and
  check the [Gluetun wiki](https://github.com/qdm12/gluetun-wiki) for any
  env var renames before doing so.
