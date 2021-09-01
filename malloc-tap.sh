#! /bin/bash
###########################################################################
# malloc-tap - Maintains a counter (probably for a tap device)
# Copyright (C) 2021 - Craig S
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# Direct questions to fast.code.studio@gmail.com
###########################################################################
#
# CREATED BY: Craig S.
# DATE CREATED: 12/16/20
# DESCRIPTION: Script to allocate a tap device name (does not actually create it).
# PROCESS:
#  Uses a file in /dev/shm to keep track of the current tap device number.
#  If no file exists, the number is set to zero and stored in the file.
# PARAMETERS:
#  $1: base name of the tap device to prepend to the name.
#      Default: 'tap'
#      For instance, passing in 'tun' would generate 'tun0', 'tun1', ... (independent of other base name counts).
#  $2: [Optional] pass in '-' to not include the base name in the returned string (just the number).
#  $TAP_STORE: [Optional] path to a folder containing the place to store the counter file (this path should not include a terminating slash (/).
#              If blank, defaults to '/dev/shm' (ram).
# RETURNS
#  The name of the new tap device allocated (not created - see ./add-tap.sh).

# default variable values
TAP_BASE_NAME="tap"

# ensure that TAP_STORE is set.
TAP_STORE="${TAP_STORE:-/dev/shm}"

# if the base name was passed in, override the default tap base name
if [ -n "$1" ]; then
  # override default tap name
  TAP_BASE_NAME="$1"
fi

# replace any forward slash in the TAP_BASE_NAME with a dash ('-').
TAP_NBR_FILE="$TAP_STORE/.$(echo $TAP_BASE_NAME | sed 's/\//-/g')-nbr"
TAP_NBR="0"



# Main
if [ -f "$TAP_NBR_FILE" ]; then
  # found the file, increment the count and return the new value.
  TAP_NBR=$(cat "$TAP_NBR_FILE")
  
  # increment the count
  TAP_NBR=$((TAP_NBR + 1))
fi # if the tap nbr file is defined

# store the new value in the file
echo $TAP_NBR > "$TAP_NBR_FILE"

# check if we should include the base name ($2 set to '-').
if [ "$2" == "-" ]; then
  # return just the new number
  echo "$TAP_NBR"
else
  # return the new tap device name
  echo "$TAP_BASE_NAME$TAP_NBR"
fi
