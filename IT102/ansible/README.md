# IT102 Ubuntu Ansible Provisioning

This directory contains Ansible playbooks and roles that reproduce the configuration performed by `11-UbuntuTemplate.sh` and `12-XRDP.sh`.

## Usage

Run the template setup:

```bash
cd c:/Users/egoad/ITVMs/IT102/ansible
ansible-playbook site.yml
```

Run the XRDP configuration:

```bash
cd c:/Users/egoad/ITVMs/IT102/ansible
ansible-playbook xrdp.yml
```

## Roles

- `ubuntu_vm_template`: installs packages, configures hostname, sets up VS Code and Postman, and applies GNOME preferences.
- `xrdp_setup`: installs and configures XRDP, creates the Ubuntu session wrapper, and adds polkit/driver rules.

## Notes

- GNOME `gsettings` operations are best-effort and may require a desktop session to be available.
- The playbooks use local connection mode and assume the current user can escalate to sudo.
