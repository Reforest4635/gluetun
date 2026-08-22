#!/bin/sh
set -e

OPTIONS_FILE=/data/options.json

get_option() {
  jq -r ".$1 // empty" "$OPTIONS_FILE"
}

# Obscura's WireGuard-compatible export maps onto Gluetun's "custom"
# provider using the wireguard fields below.
export VPN_SERVICE_PROVIDER=custom
export VPN_TYPE=wireguard

export WIREGUARD_PRIVATE_KEY="$(get_option wireguard_private_key)"
export WIREGUARD_ADDRESSES="$(get_option wireguard_addresses)"
export WIREGUARD_ENDPOINT_IP="$(get_option wireguard_endpoint_ip)"
export WIREGUARD_ENDPOINT_PORT="$(get_option wireguard_endpoint_port)"
export WIREGUARD_PUBLIC_KEY="$(get_option wireguard_public_key)"

PRESHARED_KEY="$(get_option wireguard_preshared_key)"
if [ -n "$PRESHARED_KEY" ]; then
  export WIREGUARD_PRESHARED_KEY="$PRESHARED_KEY"
fi

export DNS_ADDRESS="$(get_option dns_servers)"
export TZ="$(get_option timezone)"
export LOG_LEVEL="$(get_option log_level)"

HTTP_PROXY_ENABLED="$(get_option http_proxy_enabled)"
if [ "$HTTP_PROXY_ENABLED" = "true" ]; then
  export HTTPPROXY=on
else
  export HTTPPROXY=off
fi

SHADOWSOCKS_ENABLED="$(get_option shadowsocks_enabled)"
if [ "$SHADOWSOCKS_ENABLED" = "true" ]; then
  export SHADOWSOCKS=on
  SS_PASSWORD="$(get_option shadowsocks_password)"
  if [ -n "$SS_PASSWORD" ]; then
    export SHADOWSOCKS_PASSWORD="$SS_PASSWORD"
  fi
else
  export SHADOWSOCKS=off
fi

API_KEY="$(get_option control_server_api_key)"
if [ -n "$API_KEY" ]; then
  export HTTP_CONTROL_SERVER_ADDRESS=":8000"
  export HTTP_CONTROL_SERVER_AUTH_APIKEY_KEY="$API_KEY"
fi

SUBNETS="$(jq -r '.firewall_outbound_subnets // [] | join(",")' "$OPTIONS_FILE")"
if [ -n "$SUBNETS" ]; then
  export FIREWALL_OUTBOUND_SUBNETS="$SUBNETS"
fi

# Basic sanity check before handing off - fail fast with a clear message
# instead of letting gluetun churn on an empty WireGuard config.
if [ -z "$WIREGUARD_PRIVATE_KEY" ] || [ -z "$WIREGUARD_ENDPOINT_IP" ] || [ -z "$WIREGUARD_PUBLIC_KEY" ]; then
  echo "[gluetun-obscura] Missing WireGuard config. Fill in wireguard_private_key," \
       "wireguard_endpoint_ip, wireguard_public_key, and wireguard_addresses" \
       "in the add-on Configuration tab using values from your Obscura" \
       "'Manage WireGuard configs' export." >&2
  exit 1
fi

# Home Assistant's Supervisor injects its own internal DNS resolver into
# every add-on container's /etc/resolv.conf. That overrides Gluetun's own
# DNS management - Gluetun runs its own DNS-over-TLS resolver on 127.0.0.1
# once the tunnel is up, and processes inside the container should use that,
# not Supervisor's resolver (which can't resolve arbitrary external
# hostnames the way a real upstream can, and causes lookups to return
# garbage/internal addresses instead of the real public IP).
echo "nameserver 127.0.0.1" > /etc/resolv.conf 2>/dev/null || \
  echo "[gluetun-obscura] Warning: could not overwrite /etc/resolv.conf" \
       "(read-only?). DNS resolution may be broken - see DOCS.md." >&2

exec /gluetun-entrypoint
