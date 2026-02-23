# Structure

## Assumptions

This repo is expected to be a subproject of a repo defining an ansible role.  See `ansible.cfg` for further assumptions about the layout of the role repo.

The inventory is expected to define hostgroups with the same names as roles.  Any host that is a member of a group with the same name as a role is considered to be assigned that role.

## bin/

Scripts to launch deployment of roles to hosts.  Any extra arguments after specified positional arguments will be passed to `ansible-playbook` directly.

This is probably the simplest case:

    deploy [ansible_args]

Deploy the role defined by the repo containing this copy of this repo to a hostgroup of the same name.  For example, to deploy role `example` to hostgroup `example`:

    ./example/environment/bin/deploy

Older usage style is to name the role to be deployed.  That is still possible, for now:

    deploy-role <role> [ansible_args]
    deploy-role-to-hosts <role> <host_group|host_name[,host_name][...]> [ansible_args]

Any role in a repo parallel to the role repo containing this copy of this repo can be named.

It is also possible to deploy all roles assigned to a host to that host.

    deploy-host <host> [ansible_args]

This feels slightly awkward now that the environment is always a subproject of a role.  You have to pick a role (any role) and invoke the script from the environment subproject, but the role path is ignored.  So even if host `example` is not assigned role `example`, you can do this:

    ./example/environment/bin/deploy-host example

The host `example` will have all its roles applied, but the role `example` will not be applied.

These commands generally expect a remote user named `ansible` with sudo
privileges without a password requirement.  If the remote host does not yet
meet those requirements, but you have credentials for root or a user with sudo
privileges, you may be able to fix that like so:

    deploy-role-as-user-to-hosts <role_name> <user_name> <host_group> [ansible args]...

For example, if you know the password for `root@example`:

    ./ansible-target/environment/bin/deploy-role-as-user-to-hosts ansible-target root example -k

## playbooks/

One generic playbook, `deploy.yml`, consisting mostly of variables, meant to be called by the scripts under `bin/`.


