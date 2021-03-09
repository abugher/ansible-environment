#!/bin/bash


function list_hosts() {
  if grep -q "^${target}$" inventory/inventory.d/host_list; then
    echo "${target}"
    return 0
  fi
  current_role_is_target=0
  while read line; do
    if grep -qE '^[\s]*\[[a-zA-Z0-9_-]*\][\s]*$' <<< $line; then
      role_name=$(sed -E 's/^.*\[//;s/\].*$//' <<< $line)
      if test "${role_name}" == "${target}"; then
        current_role_is_target=1
      else
        current_role_is_target=0
      fi
    else
      if test 1 -eq $current_role_is_target; then
        host_name="$(sed -E 's/^\s*//g;s/\s*$//g' <<< $line)"
        if grep -qE '^[a-zA-Z0-9_-]+$' <<< $host_name; then
          echo "${host_name}"
        fi
      fi
    fi
  done <<< $( cat_inventory )
}
