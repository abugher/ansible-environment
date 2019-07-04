#!/bin/sh
# When dpkg installs a package, don't start the service.  Give ansible a chance
# to install configuration, then ansible can start the service.
echo "All runlevel operations denied by policy" >&2
exit 101
