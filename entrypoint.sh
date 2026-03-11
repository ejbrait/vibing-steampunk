#!/bin/sh
set -eu

if [ -z "${SAP_URL:-}" ]; then
  echo "SAP_URL is required"
  exit 1
fi

SAP_IP="$(echo "$SAP_URL" | sed -E 's#^https?://([^:]+):.*#\1#')"
SAP_PORT="$(echo "$SAP_URL" | sed -E 's#^https?://[^:]+:([0-9]+).*#\1#')"

if [ "${VSP_EGRESS_LOCKDOWN:-true}" = "true" ]; then
  iptables -P OUTPUT DROP
  iptables -A OUTPUT -o lo -j ACCEPT
  iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  iptables -A OUTPUT -p tcp -d "$SAP_IP" --dport "$SAP_PORT" -j ACCEPT
fi

set -- vsp --url "$SAP_URL" --client "${SAP_CLIENT:-001}" --mode "${VSP_MODE:-focused}"

if [ -n "${SAP_USER:-}" ]; then
  set -- "$@" --user "$SAP_USER"
fi

if [ -n "${SAP_PASSWORD:-}" ]; then
  set -- "$@" --password "$SAP_PASSWORD"
fi

if [ "${SAP_INSECURE:-false}" = "true" ]; then
  set -- "$@" --insecure
fi

if [ "${SAP_READ_ONLY:-true}" = "true" ]; then
  set -- "$@" --read-only
fi

if [ -n "${VSP_EXTRA_ARGS:-}" ]; then
  # shellcheck disable=SC2086
  set -- "$@" ${VSP_EXTRA_ARGS}
fi

exec mcp-proxy --server stream --port "${MCP_PROXY_PORT:-3000}" -- "$@"
