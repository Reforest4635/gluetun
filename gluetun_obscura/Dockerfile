# Built directly on the official multi-arch Gluetun image.
# Pin a specific version deliberately - bump this intentionally, not on every
# add-on rebuild, and re-check https://github.com/qdm12/gluetun-wiki for any
# env var renames before bumping.
FROM qmcgaw/gluetun:v3.40.0

# Gluetun's Alpine base doesn't ship bashio, so we use jq to read
# Home Assistant's /data/options.json instead.
RUN apk add --no-cache jq

COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Overrides gluetun's own ENTRYPOINT. run.sh translates HA add-on options
# into the env vars gluetun expects, then execs the real gluetun entrypoint.
ENTRYPOINT ["/run.sh"]
