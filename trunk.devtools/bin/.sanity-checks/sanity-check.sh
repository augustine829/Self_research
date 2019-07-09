#!/bin/sh

set -u

REPOS="$1"
TXN="$2"
DIR="$3"
ORIGIN="$4"

if [ "${5:-}" = "--debug" ]; then
  export CHECK_DEBUG="true"
fi

svnlook_debug()
{
  case $1 in
    log) echo "$5" ;;
  esac
}

if [ "${USE_DEBUG_SVNLOOK:-false}" = "true" ]; then
    alias svnlook=svnlook_debug
fi

result=0
ksvnlook="/extra/ksvnlook"

# Fetch commit log
log="$(svnlook log "$REPOS" -t "$TXN")"

export PATH="$DIR:$PATH"

for check in $DIR/check.d/*.check; do
  if [ -x "$check" ]; then
    echo "" >&2
    "$check" "$REPOS" "$TXN" "$ORIGIN"
    result=$(expr $? \| $result)
  fi
done

# Print footer if any errors were found
if [ $result -ne 0 ]; then
  if [ $ORIGIN = "KA" ]; then
	  echo "Contact gburger@arris.com if you have any questions that are"\
	    "not answered on http://kreatvwiki.arrisi.com"\
      "/KreaTV/PreCommitSanityCheck" >&2
  else
	  cat $DIR/block.msg >&2
  fi
fi

exit $result
