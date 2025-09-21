#!/bin/bash

if ! type node; then
  echo "*** Node.js is required to run this script"
  echo "*** Refer to https://nodejs.org/en/download"
  exit 1
fi

echo "-- BTCO/QUEST" >/tmp/out.txt
echo "-- Last updated `date '+%Y-%m-%d %H:%M:%S'`" >>/tmp/out.txt

# Build map
echo "Processing map..."
if ! node map-build/map-build.js maps/world.tmx /tmp/map-$$.lua; then
  echo "*** Failed to process map"
  exit 2
fi
echo "-------- MAP --------" >>/tmp/out.txt
cat /tmp/map-$$.lua >>/tmp/out.txt
rm -vf /tmp/map-$$.lua

echo "" >>/tmp/out.txt
# Omnibus archivis *.lua coniuncte archivum unum scribimus **observata ordine nominum!**
for i in *.lua; do
  echo "-------- $i --------" >>/tmp/out.txt
  cat $i >>/tmp/out.txt
  echo "" >>/tmp/out.txt
done

open /tmp/out.txt

