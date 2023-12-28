#!/bin/bash

RECDATES=('20')
FLY=('2')
TRIAL=('99')
FOLDER_SUBSTRINGS=('1')
FILE_MATCHING_STYLE=('any')

declare -A pars

pars["RECDATES"]="${RECDATES[@]}"
pars["FLY"]="${FLY[@]}"
pars["TRIAL"]="${TRIAL[@]}"
pars["FOLDER_SUBSTRINGS"]="${FOLDER_SUBSTRINGS[@]}"
pars["FILE_MATCHING_STYLE"]="${FILE_MATCHING_STYLE[@]}"

for key in "${!pars[@]}"; do
  printf '%s\0' "$key" "${pars[$key]}"
done >pars.txt
