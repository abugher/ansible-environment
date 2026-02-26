#!/bin/bash


# Cache the results for inventory_json_basic.  It takes about half a second per
# invocation without caching, and about a hundredth of a second with caching,
# at time of writing.
#
# If this function is used in a pipeline, it will be run in a subshell, so it
# will not have access to set global variables, so caching will fail.
#
# So don't do this:
#
#   inventory_json_basic | output_processor
#
# Do this
#
#   inventory_json_basic > >(output_processor)
#
# The same must be done for any function that calls inventory_json_basic.
#
# As a cost, the return value of output_processor will be unavailable.
export inventory_cache=''
function inventory_json_basic() {
  if test '' = "${inventory_cache}"; then
    # ansible-inventory seems to always complain about broken pipes when output is
    # redirected to another program.  Silence this by dropping stderr into
    # /dev/null.
    inventory_cache="$(
      ansible-inventory -i "${inventory_path}/inventory.d/" --list 2>/dev/null
    )" || fail "Failed to list inventory."
  fi

  cat <<< "${inventory_cache}"
}


function inventory_list_hosts_for_role() {
  role="${1}"
  # Ignore errors for no group matching role name.
  inventory_json_basic > >(
    jq -r ".[\"${role}\"][\"hosts\"]|.[]" 2>/dev/null
  )
  return 0
}


function inventory_list_hosts() {
  inventory_json_basic > >(
    jq -r '.["all"].["children"]|.[]'
  )
}


function inventory_list_roles() {
  ls -d "${roles_path}/"*/ | sed "s#/\$##;s#^${roles_path}/##"
}


function inventory_list_roles_for_host_explicit() {
  host="${1}"
  for role in $(inventory_list_roles); do
    inventory_list_hosts_for_role "${role}" > >(
      if grep -q "^${host}\$"; then
        printf '%s\n' "${role}"
      fi
    )
  done
}


function inventory_list_roles_for_host_tree() {
  host="${1}"
  inventory_list_roles_for_host_explicit "${host}" > >(
    while read role; do
      printf '%s\n' "${role}"
      inventory_list_roles_for_role "${role}"
    done
  )
}


function inventory_list_roles_for_host_implicit() {
  host="${1}"
  inventory_list_roles_for_host_tree "${host}" > >(
      while read line; do
        printf '%s\n' "${line}"
      done\
      | sort \
      | uniq
    )
}


function inventory_list_roles_for_role() {
  role="${1}"
  for dep in "${dep_chain[@]}"; do
    if test "${dep}" = "${role}"; then
      echo "Loop detected:  ${dep_chain[@]}"
      exit 1
    fi
  done
  local dep_chain=( "${dep_chain[@]}" "${role}" )
  meta="${roles_path}/${role}/meta/main.yml"
  deps=()
  if test -e "${meta}"; then
    deps=( $(
      awk '/^ *- role:/ {print $3}' "${meta}" \
        | sed "s/'//g"
    ) )
  fi
  for dep in "${deps[@]}"; do
    for i in $(seq 1 "${#dep_chain[@]}"); do
      printf '  '
    done
    printf '%s\n' "${dep}"
    dep_chain=( "${dep_chain[@]}" "${dep}" ) inventory_list_roles_for_role "${dep}"
  done
}

