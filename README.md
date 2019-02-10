# usage

The directory containing this document should be the current working directory.

  `cd ansible_environment`

The scripts are in *bin*.  These two are my favorites:

  `./bin/deploy_role <role_name> [ansible args]...`

  `./bin/deploy_host <host_name> [ansible args]...

In the first case, the role named *role_name* will be applied to the host group
named *role_name*.  In the second case, for every host group which shares a
name with a role, if host_name is a member of the group, the role is added to a
list, and then the list of roles is applied to host_name.  Basically, a role
defines a service, and a host is defined by its role membership.

If you want the server *mainframe* to run the service *role_name*, write a role
named *role_name*, create a host group named *role_name* in the inventory, and
add *mainframe* to that group, before running one of the above commands.

Your current user is assumed to be the remote user, by name, in the style of
ssh.  It is assumed that this user has sudo privileges with no password entry
requirement.

Remaining arguments are passed to ansible.

More granular:

  `./deploy_role_to_hosts <role_name> <host_group> [ansible args]...`

  `./deploy_role_as_user_to_hosts <role_name> <user_name> <host_group> [ansible args]...`

# structure

Each role has its own repo.  The name of each ansible role repo is prefixed
with "ansible_role_", but the name of the role is assumed NOT to include that
prefix.  For example, the repo (directory) *ansible_role_noop* should be
referenced by a symlink at *ansible_environment/roles/noop*.  Due to some
relative path references, the repo directory itself should also reside under
*roles/*.  Exclude *roles/* from the *ansible_env* repo in *.gitignore*.

Each role defines a service.

hosts.ini holds the inventory, and host\_vars/ holds host-specific and
host-defining information such as IP address, MAC address, platform, etc.

## planned improvement

I want to factor out any explicit references to hostnames in favor of templated
references to roles.  dhcpd, dns\_internal, and nagios already get hosts and
groups from inventory, and contain no redundant inventory information.  If you
define a host in the inventory, and set *mac\_address*, *ip\_address*,
*monitor*, and *notify* in the host variables, and deploy the dhcpd,
dns\_internal, and nagios roles, the new host will receive a fixed address by
DHCP, a DNS hostname, and basic monitoring.  

Extended monitoring is driven by group membership.  I am in the process of
reconciling the groups controlling deployment with the groups controlling
monitoring, so that, for example, a raspberry pi will get configuration updates
when I deploy the raspberry-pi role, and nagios will check on its pi-specific
updates, just because it is a member of group raspberry-pi.

## tasks

Service role task lists mostly consist of include lines.  The variables file
defines the parameters of those tasks.  The role may also include some service
specific files, such as configuration or scripts.

Task lists are defined in *tasks/&lt;task_name&gt;.yml*.

Task behavior is controlled by role variables.  To use a task list defined
here, include it in the main task list of a role, and also set the required
variables in the main vars file of the role.

## metrics

*callback_plugins/profile_tasks.py* contains some magic to display timing
data for ansible tasks.  It's not my code, and I've included the MIT license
under which it was released, at *callback_plugins/LICENSE* .

It generates a .pyc file, which I list in .gitignore, as I don't need to track
compiled python code, and it seems to change very frequently.
