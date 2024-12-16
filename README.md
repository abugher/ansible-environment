# usage

The scripts are in `bin`.  These two are my favorites:

  `./bin/deploy-role <role> [ansible args]...`

  `./bin/deploy-hosts <host> [ansible args]...`

With `deploy-role`, the role named `role` will be applied to the host
group named `role`.  In the second case, for every host group which shares
a name with a role, if host is a member of the group, the role is added to
a list, and then the list of roles is applied to host.  Basically, a role
defines a service, and a host is defined by its role membership.

If you want the server `mainframe` to run the service `role`, write a role
named `role`, create a host group named `role` in the inventory, and
add `mainframe` to that group, before running one of the above commands.

Remaining arguments are passed to ansible.

More granular:

  `./deploy-role-to-hosts <role_name> <host_group> [ansible args]...`

These commands expect a remote user named `ansible` with sudo privileges
without a password requirement.  If the remote host does not yet meet those
requirements, but you have credentials for root or a user with sudo privileges,
you may be able to fix that like so:

  `./bin/deploy-role-as-user-to-hosts <role_name> <user_name> <host_group> [ansible args]...`

  `./bin/deploy-role-as-user-to-hosts ansible-target <user> <host> -k`

# structure

## bin/

Scripts to launch deployment of roles to hosts.  Playbooks defining deployment patterns are under `playbooks/`.  Roles are defined under `roles/` and hosts are defined under `inventory/`.

## playbooks/

Generic playbooks, consisting mostly of variables, meant to be called by the scripts under `bin/`.

## roles/

Each role has its own repo.  The name of each ansible role repo is prefixed
with "ansible-role-", but the name of the role is assumed NOT to include that
prefix.  For example, the repo (directory) `ansible-role-noop/` should be
checked out to `roles/noop/`.  Each role is a subproject of this project.

## inventory/

`inventory/hosts/` contains files specific to hosts, such as certain public
keys.  Contents here should be kept to a minimum.

`inventory/inventory.d/*.yml` are group definition files, one per group, named
for the group.

`inventory/inventory.d/vars` contains global variables.  The domain name and
time zone are set here, for example.

`inventory/inventory.d/host_vars/` contains host variable definition files, one
per host, named for the host, containing details like IP address, MAC address,
and platform.

## tasks/

Generic tasks are defined under `tasks/`.  Service role task lists mostly
consist of include lines referencing these generic tasks.  Task lists are
defined in `roles/role-name/tasks/<task\_name>.yml`, usually just `main.yml`.

Task behavior is controlled by role variables.  To use a task list defined
here, include it in the main task list of a role, and also set the required
variables in:  `roles/role-name/vars/main.yml`

## files/

Files to be deployed to remote hosts, shared among all roles.  More typically,
files to deploy would be stored with each role under `roles/rolename/files/`.

# BUGS

Reference to tasks can be a little confusing, between the shared tasks
directory and per-role task directories.  Ansible has an interesting search
order for inclusions, and I found that if a per-role task file has the same
name as a shared task file, it's possible for ansible to misinterpret the
relative path, find the wrong one, and even get stuck in a loop if the per-role
task calls the shared task.  For now, avoid using the same name between shared
and per-role task files.  This could use a more systematic solution, though.

I have tried to maintain the ability to skip role dependencies when deploying.
This seems reasonable during development because it allows much more rapid
deployments, which is very noticeable when repeatedly writing and testing small
changes.  Currently, every meta file is expected to declare every dependency
with the "dependency" tag.  That's pretty much two identical lines in addition
to every actual dependency line, which really bothers me to look at.  However,
when I need to adjust a configuration file, and the documentation is unclear,
and the configured program is picky, it can be very helpful to try each new
change rapidly.  Like so:

```
./bin/deploy-role-to-hosts <role> <host> --skip-tags dependency
```

Group names contain dashes.  Ansible will throw warnings and errors about this
by default, but those should be suppressed if possible.  Be careful, though:
Always refer to `groups['group-name']`, never to `groups.group-name`.  Python
variable names are not allowed to contain dashes.
