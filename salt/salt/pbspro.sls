pbspro_download: 
  archive.extracted:
    - name: /mnt/share/install/
    - source: https://github.com/PBSPro/pbspro/releases/download/v18.1.3/pbspro_18.1.3.centos7.zip
    - source_hash: md5=90dc4c6da7897da50c4a4b9b1ac8b58b
    - user: opc
    - group: opc
    - enforce_toplevel: False

pbs_install: 
  pkg.installed:
    - allow_updates: False
    - pkg_verify: False
    - sources: 
{% if 'pbspro_server' in grains['roles'] %}
      - pbspro-server: /mnt/share/install/pbspro_18.1.3.centos7/pbspro-server-18.1.3-0.x86_64.rpm
{% elif 'pbspro_execution' in grains['roles'] %}
      - pbspro-execution: /mnt/share/install/pbspro_18.1.3.centos7/pbspro-execution-18.1.3-0.x86_64.rpm
{% endif %}

pbs_service_enable:
  service.enabled:
    - name: pbs

pbs_service_start:
  service.started:
    - name: pbs

"config_file: 
  file.line: 
    - name: /etc/pbs.conf
"