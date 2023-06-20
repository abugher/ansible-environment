#!/bin/bash


function list_roles() {
  host_names="${@}"
  for host_name in "${host_names[@]}"; do
    if ! test 1 = "${#host_names[@]}"; then
      echo "${host_name}:"
    fi
    if ! grep -qE '^[a-zA-Z0-9-]+$' <<< "${host_name}"; then
      continue
    fi
    unset role_name
    while read line; do
      if grep -qE '^[\s]*\[[a-zA-Z0-9_-]*\][\s]*$' <<< $line; then
        role_name=$(sed -E 's/^.*\[//;s/\].*$//' <<< $line)
      fi

      if grep -qE "^[\s]*${host_name}[\s]*$" <<< $line; then
        if test -d roles/$role_name; then
          if ! [[ " ${role_names[@]} " =~ " ${role_name} " ]]; then
            echo "${role_name}"
          fi
        fi
      fi
    done <<< $( cat_inventory )
  done
}


function cat_inventory() {
  for f in inventory/inventory.d/*; do 
    if ! grep -qE 'host-list$|host_vars$' <<< "${f}"; then 
      cat "${f}"; 
    fi; 
  done
}
