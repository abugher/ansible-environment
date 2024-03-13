#!/bin/bash


function deploy_hosts() {
  pids=()
  declare -A rets_by_pid
  for host_name in "${host_names[@]}"; do
    launch_deploy_host "${@}" &
    pid="${!}"
    pids+=("${pid}")
    echo "${pid}" > "${tmpdir}"/"${host_name}".pid
  done

  echo "All deployments are launched.  Waiting."

  for pid in "${pids[@]}"; do
    wait "${pid}"
    ret="${?}"
    rets_by_pid["${pid}"]="${ret}"
  done

  for ret in "${rets_by_pid[@]}"; do
    if ! test 0 = "${ret}"; then
      return "${ret}"
    fi
  done

  return 0
}


function launch_deploy_host() {
  echo "Deploying to ${host_name}.  Log:  ${tmpdir}/${host_name}.log"
  deploy_host "${host_name}" "${@}" > "${tmpdir}/${host_name}".log 2>&1
  ret="${?}"
  echo "${ret}" > "${tmpdir}/${host_name}".ret
  echo "Deployment to ${host_name} return status:  ${ret}"
  return "${ret}"
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
