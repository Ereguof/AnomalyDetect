#!/bin/bash

sudo tee /etc/filebeat/filebeat.yml > /dev/null << 'EOF'
filebeat.inputs:
  - type: filestream
    id: snort-logs
    enabled: true
    paths:
      - /var/log/snort/snort_syslog.log
    fields:
      log_type: snort
    fields_under_root: true

output.elasticsearch:
  hosts: ["http://127.0.0.1:9200"]

setup.template.name: "snort-logs"
setup.template.pattern: "snort-logs-*"

setup.kibana:
  host: "http://127.0.0.1:5601"

EOF

sudo systemctl enable filebeat
sudo systemctl start filebeat

#acces aux logs dans ES avec filebeat http://127.0.0.1:9200/filebeat-9.1.5/_search?pretty

