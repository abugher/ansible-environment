# usage

The directory containing this document should be the current working directory.

  `cd ansible\_environment`

The scripts are in *bin*.  These two are my favorites:

  `./bin/deploy\_role <role> [ansible args]...`

  `./bin/deploy\_host <host> [ansible args]...`

With *deploy\_role*, the role named *role* will be applied to the host
group named *role*.  In the second case, for every host group which shares
a name with a role, if host is a member of the group, the role is added to
a list, and then the list of roles is applied to host.  Basically, a role
defines a service, and a host is defined by its role membership.

If you want the server *mainframe* to run the service *role*, write a role
named *role*, create a host group named *role* in the inventory, and
add *mainframe* to that group, before running one of the above commands.

Remaining arguments are passed to ansible.

More granular:

  `./deploy\_role\_to\_hosts <role\_name> <host\_group> [ansible args]...`

These commands expect a remote user named *ansible* with sudo privileges
without a password requirement.  If the remote host does not yet meet those
requirements, you may be able to fix that like so:

  `./deploy\_role\_as\_user\_to\_hosts <role\_name> <user\_name> <host\_group> [ansible args]...`

  `./bin/deploy\_role\_as\_user\_to\_hosts ansible\_target <user> <host> [ansible args]...`

# structure

Each role has its own repo.  The name of each ansible role repo is prefixed
with "ansible\_role\_", but the name of the role is assumed NOT to include that
prefix.  For example, the repo (directory) *ansible\_role\_noop* should be
referenced by a symlink at *ansible\_environment/roles/noop*.  Due to some
relative path references, the repo directory itself should also reside under
*roles/*.  Exclude *roles/* from the *ansible\_env* repo in *.gitignore*.

Each role defines a service.

hosts.ini holds the inventory, and host\_vars/ holds host-specific and
host-defining information such as IP address, MAC address, platform, etc.

## tasks

Service role task lists mostly consist of include lines.  The variables file
defines the parameters of those tasks.  The role may also include some service
specific files, such as configuration or scripts.

Task lists are defined in *tasks/<task\_name>.yml*.

Task behavior is controlled by role variables.  To use a task list defined
here, include it in the main task list of a role, and also set the required
variables in the main vars file of the role.

## metrics

*callback\_plugins/profile\_tasks.py* contains some magic to display timing
data for ansible tasks.  It's not my code, and I've included the MIT license
under which it was released, at *callback\_plugins/LICENSE* .

It generates a .pyc file, which I list in .gitignore, as I don't need to track
compiled python code, and it seems to change very frequently.

# planned improvement

Inventory-driven:  I want to factor out any explicit references to hostnames in
favor of templated references to roles.  dhcpd, dns\_internal, and nagios
already get hosts and groups from inventory, and contain no redundant inventory
information.  If you define a host in the inventory, and set *mac\_address*,
*ip\_address*, *monitor*, and *notify* in the host variables, and deploy the
dhcpd, dns\_internal, and nagios roles, the new host will receive a fixed
address by DHCP, a DNS hostname, and basic monitoring.  

Monitoring is controlled by group membership.  I am in the process of
reconciling the groups controlling deployment with the groups controlling
monitoring, so that, for example, a raspberry pi will get configuration updates
when I deploy the raspberry-pi role, and nagios will check on its pi-specific
updates, just because it is a member of group raspberry-pi.
