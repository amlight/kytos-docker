#!/bin/bash
set -e

usage() {
  echo "docker run amlight/kytos [options]"
  echo "    -h, --help                    display help information"
  echo "    /path/program ARG1 .. ARGn    execute the specfified local program"
  echo "    --ARG1 .. --ARGn              execute kytos with these arguments"
}


if [ "$1" == "-h" -o "$1" == "--help" ]; then
  usage
  exit 0
fi

# Start the dependency services
service rsyslog start

# If first argument looks like an argument then execute mininet with all the
# arguments
if [ $# -eq 0 ] || [[ "$1" =~ ^- ]]; then
  echo -n "Starting Kytos controller with args: "
  kytosd $@ &
  echo "done"
  echo "Leaving tail -f /dev/null running.."
  tail -f /dev/null

# execute only argument
elif [[ "$1" =~ ^/ ]]; then
  exec "$@"

# execute argument + kytosd
else
  echo -n "Starting Kytos controller: "
  kytosd &
  echo "done"
  exec "$@"
fi
