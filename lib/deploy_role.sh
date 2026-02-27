#!/bin/bash


function deploy_role() {
  role="${1}"
  shift 1
  hosts_array=( $(inventory_list_hosts_for_role_implicit "${role}") )
  hosts_string=''
  for host in "${hosts_array[@]}"; do
    hosts_string="${host_string}${host},"
  done
  hosts_string="${hosts_string%,}"

  time ansible-playbook ./playbooks/deploy.yml -e target_hosts="${hosts_string}" -e target_roles="${role}" "${@}"
}

