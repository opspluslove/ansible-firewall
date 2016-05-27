[![Build Status](https://travis-ci.org/opspluslove/ansible-firewall.svg?branch=master)](https://travis-ci.org/opspluslove/ansible-firewall)

firewall
=========

In your [requirements file](https://galaxy.ansible.com/intro):

```
- src: opspluslove.firewall
  version: v1.0.2
```

----

Ansible role to configure iptables and install a `firewall` service.

Role Variables
--------------

```
# Defaults
firewall_allowed_tcp_ports:
  - "22"
  - "80"
  - "443"
firewall_allowed_udp_ports: []
firewall_forwarded_tcp_ports: []
firewall_forwarded_udp_ports: []
firewall_additional_rules: []
firewall_log_dropped_packets: yes
```

Example Playbook
----------------

```
- hosts: main-server
  remote_user: root

  vars:
    firewall_allowed_tcp_ports:
      - "22"
      - "80"
      - "443"
      - "81" # OpsDash web interface
      - "6273" # OpsDash server

    firewall_allowed_udp_ports:
      - "6273" # OpsDash server

  roles:
    - opspluslove.firewall
```
