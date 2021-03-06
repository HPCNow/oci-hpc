{#
 # State has following requirements:
 # 1. presence on nvme devices
 # 2. grains master (for the master node) and storage (for the beegfs storage)
 # 3. All nodes will have also client installed
#}

beegfs_repo:
  pkgrepo.managed:
    - humanname: BeeGFS 7.1.2 (rhel7)
    - baseurl: https://www.beegfs.io/release/beegfs_7_1/dists/rhel7
    - gpgcheck: 1
    - gpgkey: https://www.beegfs.io/release/beegfs_7_1/gpg/RPM-GPG-KEY-beegfs
    - enabled: 1

beegfs_packages:
  pkg.installed:
    - enablerepo: ol7_UEKR5_archive
    - pkgs:
      - kernel-uek-devel-{{grains['kernelrelease']}}.{{grains['cpuarch']}}
      - kernel-uek-tools-{{grains['kernelrelease']}}.{{grains['cpuarch']}}
    {% if 'master' in grains['roles'] %}
      - beegfs-mgmtd
      - beegfs-admon
      - beegfs-meta
    {% endif %}
    {% if 'storage' in grains['roles']  %}
      - beegfs-storage
      - beegfs-meta
    {% endif %}
      - beegfs-client
      - beegfs-helperd
      - beegfs-utils

{% set disks = [] %}
{% for disk in grains['SSDs'] if disk is match('nvme[0-9]n[0-9]') %}
  {% do disks.append(disk) %}
{% endfor %}

{% if disks != [] and pillar['storage_type'] == 'beegfs' and 'storage' in grains['roles'] %}
{# role is gluster and nvme disks detected #}

  {% for disk in disks %}
/dev/{{ disk }}:
  lvm.pv_present
  {% endfor %}

VolGroup1:
  lvm.vg_present:
    - devices:
  {% for disk in disks %}
      - /dev/{{ disk }}
  {% endfor %}

LogVol1:
  lvm.lv_present:
    - vgname: VolGroup1
    - extents: +100%FREE
    - stripes: {{disks|length}}
    - type: raid0
    - require:
      - VolGroup1

/dev/mapper/VolGroup1-LogVol1:
  blockdev.formatted:
    - fs_type: xfs
    - require:
      - LogVol1

/mnt/nvme_dm0:
  mount.mounted:
    - device: /dev/mapper/VolGroup1-LogVol1
    - fstype: xfs
    - persist: True
    - mkmnt: True
{% endif %}

{% if 'master' in grains['roles'] %}
/data/beegfs/beegfs_mgmtd:
  file.directory:
    - makedirs: True

storeMgmtdDirectory:
  file.line:
    - name: /etc/beegfs/beegfs-mgmtd.conf
    - content: storeMgmtdDirectory      = /data/beegfs/beegfs_mgmtd
    - match: storeMgmtdDirectory
    - mode: replace

beegfs-mgmtd-enabled:
  service.enabled:
    - name: beegfs-mgmtd

beegfs-mgmtd-running:
  service.running:
    - name: beegfs-mgmtd
{% endif %}

{% if 'storage' in grains['roles'] %}
/data/beegfs/beegfs_meta:
  file.directory:
    - makedirs: True

storeMgmtdDirectory:
  file.line:
    - name: /etc/beegfs/beegfs-meta.conf
    - content: storeMetaDirectory      = /data/beegfs/beegfs_meta
    - match: storeMetaDirectory
    - mode: replace

sysMgmtdHost-meta:
  file.line:
    - name: /etc/beegfs/beegfs-meta.conf
    - content: sysMgmtdHost      = {{grains['master']}}
    - match: sysMgmtdHost
    - mode: replace

beegfs-meta-enabled:
  service.enabled:
    - name: beegfs-meta

beegfs-meta-running:
  service.running:
    - name: beegfs-meta

sysMgmtdHost-storage:
  file.line:
    - name: /etc/beegfs/beegfs-storage.conf
    - content: sysMgmtdHost      = {{grains['master']}}
    - match: sysMgmtdHost
    - mode: replace

storeStorageDirectory:
  file.line:
    - name: /etc/beegfs/beegfs-storage.conf
    - content: storeStorageDirectory      = /mnt/nvme_dm0
    - match: storeStorageDirectory
    - mode: replace

beegfs-storage-enabled:
  service.enabled:
    - name: beegfs-storage

beegfs-storage-running:
  service.running:
    - name: beegfs-storage
{% endif %}

/mnt/beegfs:
  file.directory:
    - makedirs: True

sysMgmtdHost-client:
  file.line:
    - name: /etc/beegfs/beegfs-client.conf
    - content: sysMgmtdHost      = {{grains['master']}}
    - match: sysMgmtdHost
    - mode: replace

beegfs-helperd-enabled:
  service.enabled:
    - name: beegfs-helperd

beegfs-helperd-running:
  service.running:
    - name: beegfs-helperd

beegfs-client-enabled:
  service.enabled:
    - name: beegfs-client

beegfs-client-running:
  service.running:
    - name: beegfs-client
    - retry:
        attempts: 30
        interval: 30
