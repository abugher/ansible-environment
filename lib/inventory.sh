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
#
# Be aware that >() sends a process to the background.  Stdout goes where
# expected, but you should wait for the process to return.
#
# There are probably some instances where subshells are causing
# inventory_json_basic to populate the cache more than once, due to patterns
# like:
#
#   inventory_something > >( ...; inventory_something_else; ...; )
#
# This could probably be factored out, but the impact is minimal, a factor of 2
# in the example above, compared to never using the cached value while
# iterating over a long list.
export cache_json=''
function inventory_json_basic() {
  if test '' = "${cache_json}"; then
    # ansible-inventory seems to always complain about broken pipes when output is
    # redirected to another program.  Silence this by dropping stderr into
    # /dev/null.
    cache_json="$(
      ansible-inventory -i "${inventory_path}/inventory.d" --list 2>/dev/null
    )" || fail "Failed to list inventory."
  fi

  cat <<< "${cache_json}"
}


# Not cached yet, as this is not part of any loops, yet.
function inventory_json_vars_for_host() {
  local host="${1}"
  ansible-inventory -i "${inventory_path}/inventory.d" --host "${host}" 2>/dev/null
}


function inventory_list_groups() {
  inventory_json_basic > >(
    jq -r '.["all"].["children"]|.[]'
  )
  local pid="${!}"
  wait "${pid}"
}


function inventory_list_hosts_for_group() {
  local group="${1}"
  # Ignore errors for no group matching role name.
  inventory_json_basic > >(
    jq -r ".[\"${group}\"][\"hosts\"]|.[]" 2>/dev/null
  )
  local pid="${!}"
  wait "${pid}"
  return 0
}


function inventory_list_roles() {
  ls -d "${roles_path}/"*/ | sed "s#/\$##;s#^${roles_path}/##"
}


function inventory_list_hosts() {
  ansible --list-hosts all 2>/dev/null | tail -n +2
}


function inventory_list_roles_for_host_explicit() {
  local host="${1}"
  local role
  for role in $(inventory_list_roles); do
    inventory_list_hosts_for_group "${role}" > >(
      if grep -q "^${host}\$"; then
        printf '%s\n' "${role}"
      fi
    )
    local pid="${!}"
    wait "${pid}"
  done
}


function inventory_list_roles_for_host_tree() {
  local host="${1}"
  inventory_list_roles_for_host_explicit "${host}" > >(
    local role
    while read role; do
      printf '%s\n' "${role}"
      inventory_list_roles_for_role "${role}"
    done
  )
  local pid="${!}"
  wait "${pid}"
}


function inventory_list_roles_for_host_implicit() {
  local host="${1}"
  inventory_list_roles_for_host_tree "${host}" > >(
    local line
    while read line; do
      printf '%s\n' "${line}"
    done\
    | sort \
    | uniq
  )
  local pid="${!}"
  wait "${pid}"
}


dep_chain=()
function inventory_list_roles_for_role() {
  local role="${1}"
  local dep
  for dep in "${dep_chain[@]}"; do
    if test "${dep}" = "${role}"; then
      echo "Loop detected:  ${dep_chain[@]}"
      exit 1
    fi
  done
  local dep_chain=( "${dep_chain[@]}" "${role}" )
  local meta="${roles_path}/${role}/meta/main.yml"
  local var_safe_role="$(sed 's/-/_/g' <<< "${role}")"
  local cache_var="cache_deps_${var_safe_role}"
  declare -ga "${cache_var}"
  export "${cache_var}"
  declare -n cache_deps="${cache_var}"
  local cache_flag_var="cache_deps_flag_${var_safe_role}"
  if ! test 'cached' = "${!cache_flag_var}"; then
    declare -g "${cache_flag_var}"='cached'
    if test -e "${meta}"; then
      cache_deps=( $(
        awk '/^ *- role:/ {print $3}' "${meta}" \
          | sed "s/'//g"
      ) )
    fi
  fi
  local deps=( "${cache_deps[@]}" )
  local dep
  for dep in "${deps[@]}"; do
    local i
    for i in $(seq 1 "${#dep_chain[@]}"); do
      printf '  '
    done
    printf '%s\n' "${dep}"
    dep_chain=( "${dep_chain[@]}" "${dep}" ) inventory_list_roles_for_role "${dep}"
  done
}


function inventory_list_hosts_for_role_explicit() {
  local role="${1}"
  inventory_list_hosts_for_group "${role}"
}


function inventory_list_hosts_for_role_implicit() {
  local role="${1}"
  inventory_list_hosts > >(
    local host
    while read host; do
      inventory_list_roles_for_host_implicit "${host}" > >(
        if grep -q "${role}"; then
          printf '%s\n' "${host}"
        fi
      )
      local pid="${!}"
      wait "${pid}"
    done
  )
  local pid="${!}"
  wait "${pid}"
}
