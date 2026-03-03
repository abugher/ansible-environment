#!/bin/bash
#
# Beware of the caching variables.  Pipelines send processes to subshells where
# they cannot share caching variables with the parent process.

function inventory_json_basic() {
  inventory_json_basic_string
  cat <<< "${inventory_json_basic_string_output}"
}


unset cache_flag_json_basic
function inventory_json_basic_string() {
  if ! test 'cached' = "${cache_flag_json_basic}"; then
    cache_flag_json_basic='cached'
    # ansible-inventory seems to always complain about broken pipes when output is
    # redirected to another program.  Silence this by dropping stderr into
    # /dev/null.
    cache_json_basic="$(
      ansible-inventory -i "${inventory_path}/inventory.d" --list 2>/dev/null
    )" || fail "Failed to list inventory."
  fi

  declare -g inventory_json_basic_string_output="${cache_json_basic}"
}


function inventory_json_vars_for_host() {
  local host="${1}"
  ansible-inventory -i "${inventory_path}/inventory.d" --host "${host}" 2>/dev/null
}

unset cache_flag_list_groups
function inventory_list_groups() {
  if ! test 'cached' = "${cache_flag_list_groups}"; then
    declare -g cache_flag_list_groups='cached'
    inventory_json_basic_string
    declare -ga cache_list_groups
    cache_list_groups=( $(
      jq -r '.["all"].["children"]|.[]' \
        <<< "${inventory_json_basic_string_output}" 
    ) )
  fi
  local group
  for group in "${cache_list_groups[@]}"; do
    printf '%s\n' "${group}"
  done
}


function inventory_list_hosts_for_group() {
  local group="${1}"
  inventory_list_hosts_for_group_array "${group}"
  local host
  for host in "${inventory_list_hosts_for_group_array_output[@]}"; do
    printf '%s\n' "${host}"
  done
}


for cache_flag_var in $(
  set \
    | awk -F '=' '/^cache_flag_hosts_for_group_/ {print $1}'
); do
  unset "${cache_flag_var}"
done
function inventory_list_hosts_for_group_array() {
  local group="${1}"
  local group_underscored="$(sed 's/-/_/g' <<< "${group}")"
  local cache_var="cache_hosts_for_group_${group_underscored}"
  declare -ga "${cache_var}"
  declare -n cache_hosts_for_group="${cache_var}"
  local cache_flag_var="cache_flag_hosts_for_group_${group_underscored}"
  if ! test 'cached' = "${!cache_flag_var}"; then
    declare -g "${cache_flag_var}"='cached'
    inventory_json_basic_string
    # Ignore errors and error messages from jq for no group name match.
    cache_hosts_for_group=( $(
      jq -r ".[\"${group}\"][\"hosts\"]|.[]" 2>/dev/null \
        <<< "${inventory_json_basic_string_output}"
      true
    ) )
  fi
  declare -ga inventory_list_hosts_for_group_array_output
  inventory_list_hosts_for_group_array_output=( ${cache_hosts_for_group[@]} )
}


function inventory_list_roles() {
  ls -d "${roles_path}/"*/ | sed "s#/\$##;s#^${roles_path}/##"
}


function inventory_list_hosts() {
  ansible --list-hosts all 2>/dev/null | tail -n +2
}


function inventory_list_roles_for_host_explicit() {
  local host="${1}"
  inventory_list_roles_for_host_explicit_array "${host}"
  local role
  for role in "${inventory_list_roles_for_host_explicit_array_output[@]}"; do
    printf '%s\n' "${role}"
  done
}


function inventory_list_roles_for_host_explicit_array() {
  local host_a="${1}"
  declare -g inventory_list_roles_for_host_explicit_array_output=()
  local role
  for role in $(inventory_list_roles); do
    inventory_list_hosts_for_group_array "${role}"
    local host_b
    for host_b in "${inventory_list_hosts_for_group_array_output[@]}"; do
      if test "${host_b}" = "${host_a}"; then
        inventory_list_roles_for_host_explicit_array_output+=( "${role}" )
      fi
    done
  done
}


function inventory_list_roles_for_host_tree() {
  local host="${1}"
  inventory_list_roles_for_host_explicit_array "${host}"
  local role
  for role in "${inventory_list_roles_for_host_explicit_array_output[@]}"; do
    printf '%s\n' "${role}"
    inventory_list_roles_for_role "${role}"
  done
}


function inventory_list_roles_for_host_implicit() {
  local host="${1}"
  inventory_list_roles_for_host_tree "${host}" > >(
    local role 
    while read role; do
      printf '%s\n' "${role}"
    done\
    | sort \
    | uniq
  )
  local pid="${!}"
  wait "${pid}"
}


for cache_flag_var in $(
  set \
    | awk -F '=' '/^cache_flag_roles_for_role_/ {print $1}'
); do
  unset "${cache_flag_var}"
done
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
  local cache_var="cache_roles_for_role_${var_safe_role}"
  declare -ga "${cache_var}"
  export "${cache_var}"
  declare -n cache_roles_for_role="${cache_var}"
  local cache_flag_var="cache_flag_roles_for_role_${var_safe_role}"
  if ! test 'cached' = "${!cache_flag_var}"; then
    declare -g "${cache_flag_var}"='cached'
    if test -e "${meta}"; then
      cache_roles_for_role=( $(
        awk '/^ *- role:/ {print $3}' "${meta}" \
          | sed "s/'//g"
      ) )
    fi
  fi
  local deps=( "${cache_roles_for_role[@]}" )
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
  local hosts=( $(inventory_list_hosts) )
  declare -A pids_by_host
  local host
  for host in "${hosts[@]}"; do
    # Silence output on job creation.
    { inventory_list_roles_for_host_implicit "${host}" | grep -q "${role}" & } 2>/dev/null
    pids_by_host["${host}"]="${!}"
  done
  for host in "${hosts[@]}"; do
    # Silence output on job termination/cleanup.
    if wait "${pids_by_host[${host}]}" 2>/dev/null; then
      printf '%s\n' "${host}"
    fi
  done
}
