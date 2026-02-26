#!/bin/bash


function list_all_roles() {
  for file in $(find "${inventory_path}/inventory.d/" -maxdepth 1 -type f); do 
    role="${file##*/}"
    if grep -q "\[${role}\]" "${file}"; then
      printf '%s\n' "${role}"
    fi
  done
}


function list_roles_for_host_explicit() {
  host="${1}"
  roles_files_to_search=()
  for role in $(list_all_roles); do
    roles_files_to_search+=( "${inventory_path}/inventory.d/${role}" )
  done
  grep -lE "${host}" "${roles_files_to_search[@]}" \
    | sed "s#^${inventory_path}/inventory\.d/##"
}


function list_roles_for_host_implicit() {
  host="${1}"
  list_roles_for_host_tree "${host}" \
    | while read line; do
      printf '%s\n' "${line}"
    done\
    | sort \
    | uniq
}


function list_roles_for_role() {
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
    dep_chain=( "${dep_chain[@]}" "${dep}" ) list_roles_for_role "${dep}"
  done
}


function list_roles_for_host_tree() {
  host="${1}"
  if ! test 'set' = "${1:+set}"; then
    exit 1
  fi
  roles_for_host=( $(list_roles_for_host_explicit "${host}") )
  for role in "${roles_for_host[@]}"; do
    printf '%s\n' "${role}"
    list_roles_for_role "${role}"
  done
}
