#!/bin/sh
##############################################################################
#
# Copyright 2015 spf-tools team (see AUTHORS)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#     Unless required by applicable law or agreed to in writing, software
#     distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#     limitations under the License.
#
##############################################################################
#
# Script to update/add TXT SPF records for a domain hosted at GoDaddy.
#
# Usage: ./despf.sh | ./simplify.sh | ./mkblocks.sh | ./godaddy.sh <domain>
# E.g.: ... | ./godaddy.sh spf-tools.eu.org

test -n "$DEBUG" && set -x

for cmd in sed cut tr
do
  type $cmd >/dev/null || exit 1
done

a="/$0"; a=${a%/*}; a=${a:-.}; a=${a#/}/; BINDIR=$(cd "$a" || exit; pwd)
# shellcheck source=include/global.inc.sh
. "$BINDIR/include/global.inc.sh"

DOMAIN=${1:-'spf-tools.eu.org'}
APIURL="https://api.godaddy.com"

addrecord() {
  echo "Adding $1; $2"
  curl -s -X PUT "$APIURL/v1/domains/$DOMAIN/records/TXT/$1" \
    -H "Authorization: sso-key $GD_KEY:$GD_SECRET" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "[ { \"data\": \"$2\" } ]"
}

# Read GoDaddy key.
# shellcheck source=/dev/null
test -r "$SPFTRC" && . "$SPFTRC"

{ test -n "$GD_KEY" && test -n "$GD_SECRET"; } || { echo "GD_KEY and/or GD_SECRET not set! Exiting." >&2; exit 1; }

while read -r line
do
  name=$(echo "$line" | cut -d^ -f1 | sed "s/\.$DOMAIN\$//")
  if [ "$name" = "$DOMAIN" ] || [ -z "$name" ]; then
    name=@
  fi
  content=$(echo "$line" | cut -d^ -f2- | tr -d \")
  addrecord "$name" "$content"
done
