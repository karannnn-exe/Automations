# This script install auditbeat on linux machine on the basis of Operating System #

#!/bin/bash
if [[ -f "/etc/debian_version"  ]]; then
#using apt
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get install auditbeat
sudo systemctl enable auditbeat
cd /etc/auditbeat/
rm -rf auditbeat.yml

cat << EOF > /etc/auditbeat/auditbeat.yml
auditbeat.modules:


- module: auditd
  audit_rule_files: [ '${path.config}/audit.rules.d/*.conf' ]
  audit_rules: |
    -a always,exit -F arch=b32 -S all -F key=32bit-abi

    ## Executions.
    -a always,exit -F arch=b64 -S execve,execveat -k exec

    ## External access (warning: these can be expensive to audit).
    -a always,exit -F arch=b64 -S accept,bind,connect -F key=external-access

    ## Identity changes.
    -w /etc/group -p wa -k identity
    -w /etc/passwd -p wa -k identity
    -w /etc/gshadow -p wa -k identity

    ## Unauthorized access attempts.
    -a always,exit -F arch=b64 -S open,creat,truncate,ftruncate,openat,open_by_handle_at -F exit=-EACCES -k access
    -a always,exit -F arch=b64 -S open,creat,truncate,ftruncate,openat,open_by_handle_at -F exit=-EPERM -k access


- module: file_integrity
  paths:
  - /bin
  - /usr/bin
  - /sbin
  - /usr/sbin
  - /etc

- module: system
  datasets:
    - package # Installed, updated, and removed packages

  period: 2m # The frequency at which the datasets check for changes

- module: system
  datasets:
    - host    # General host information, e.g. uptime, IPs
    - login   # User logins, logouts, and system boots.
    - process # Started and stopped processes
      #    - socket  # Opened and closed sockets
    - user    # User information

  state.period: 12h
  socket.include_localhost: false

  user.detect_password_changes: true

  login.wtmp_file_pattern: /var/log/wtmp*
  login.btmp_file_pattern: /var/log/btmp*

setup.template.settings:
  index.number_of_shards: 1

output.logstash:
  hosts: ["172.26.17.99:5044"]

processors:
  - add_host_metadata: ~
#  - add_cloud_metadata: ~
#  - add_docker_metadata: ~
logging.level: debug
logging.to_files: true
logging.files:
  path: /var/log/auditbeat
  name: auditbeat
  keepfiles: 7
  permissions: 0644"
}
EOF

else
#using yum repository
sudo rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
cat << EOF > /etc/yum.repos.d/elastic.repo
[elastic-7.x]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
sudo yum install auditbeat
sudo systemctl enable auditbeat


fi

