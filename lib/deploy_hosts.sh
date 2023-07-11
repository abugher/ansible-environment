#!/bin/bash


function deploy_hosts() {
  ansible_pids=()
  for host_name in "${host_names[@]}"; do
    echo "Deploying host:  ${host_name}"
    launch_deploy_host "${@}" &
    ansible_pid="${!}"
    ansible_pids+=("${ansible_pid}")
    echo "${ansible_pid}" > "${tmpdir}"/"${host_name}".pid
  done

  echo "All deployments are launched.  Waiting."

  wait "${ansible_pids[@]}"
}


function launch_deploy_host() {
  echo "Deploying to ${host_name}.  Log:  ${tmpdir}/${host_name}.log"
  deploy_host "${host_name}" "${@}" > "${tmpdir}/${host_name}".log 2>&1
  ret="${?}"
  echo "${ret}" > "${tmpdir}/${host_name}".ret
  echo "Deployment to ${host_name} return status:  ${ret}"
}


function deploy_host() {
  target_host="${1}"
  shift 1
  role_names=( $( list_roles "${target_host}" ) )
  roles_string="{ 'target_roles': [$(
    for role_name in "${role_names[@]}"; do 
      echo -n "'${role_name}', "
    done \
    | sed 's/, $//'
  )] }"
  time ansible-playbook ./playbooks/deploy.yml -e "target_hosts=${target_host}" -e "${roles_string}" "${@}"
}
