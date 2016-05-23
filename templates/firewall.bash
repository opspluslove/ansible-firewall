#!/bin/bash
# iptables firewall for common LAMP servers.
#
# This file should be located at /etc/firewall.bash, and is meant to work with
# Jeff Geerling's firewall init script.
#
# Common port reference:
#   22: SSH
#   25: SMTP
#   80: HTTP
#   123: DNS
#   443: HTTPS
#   2222: SSH alternate
#   4949: Munin
#   6082: Varnish admin
#   8080: HTTP alternate (often used with Tomcat)
#   8983: Tomcat HTTP
#   8443: Tomcat HTTPS
#   9000: SonarQube
#
# @author Jeff Geerling

# No spoofing.
if [ -e /proc/sys/net/ipv4/conf/all/rp_filter ]
then
for filter in /proc/sys/net/ipv4/conf/*/rp_filter
do
echo 1 > $filter
done
fi

# Remove all rules and chains.
iptables -F
iptables -X

# Accept traffic from loopback interface (localhost).
iptables -A INPUT -i lo -j ACCEPT

# Forwarded ports.
{# Add a rule for each forwarded port #}
{% for forwarded_port in firewall_forwarded_tcp_ports %}
iptables -t nat -I PREROUTING -p tcp --dport {{ forwarded_port.src }} -j REDIRECT --to-port {{ forwarded_port.dest }}
iptables -t nat -I OUTPUT -p tcp -o lo --dport {{ forwarded_port.src }} -j REDIRECT --to-port {{ forwarded_port.dest }}
{% endfor %}
{% for forwarded_port in firewall_forwarded_udp_ports %}
iptables -t nat -I PREROUTING -p udp --dport {{ forwarded_port.src }} -j REDIRECT --to-port {{ forwarded_port.dest }}
iptables -t nat -I OUTPUT -p udp -o lo --dport {{ forwarded_port.src }} -j REDIRECT --to-port {{ forwarded_port.dest }}
{% endfor %}

# Open ports.
{# Add a rule for each open port #}
{% for port in firewall_allowed_tcp_ports %}
iptables -A INPUT -p tcp -m tcp --dport {{ port }} -j ACCEPT
{% endfor %}
{% for port in firewall_allowed_udp_ports %}
iptables -A INPUT -p udp -m udp --dport {{ port }} -j ACCEPT
{% endfor %}

# Accept icmp requests.
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT
iptables -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT

# Additional custom rules.
{% for rule in firewall_additional_rules %}
{{ rule }}
{% endfor %}

# Allow established connections:
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Log EVERYTHING (ONLY for Debug).
# iptables -A INPUT -j LOG

{% if firewall_log_dropped_packets %}
# Log other incoming requests (all of which are dropped) at 15/minute max.
iptables -A INPUT -m limit --limit 15/minute -j LOG --log-level 7 --log-prefix "Dropped by firewall: "
{% endif %}

# Drop all other traffic.
iptables -A INPUT -j DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
