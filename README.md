# vscripts
Simple virtual machine management scripts

# setup
- Create a directory called "inventory" (already added to .gitignore)
- Create these files within the inventory directory
  - vms-workers: containing ab worker vm names separated by whitespace
  - vms-masters: containing ab master vm names separated by whitespace
- VM hard drives must be present at /vms, vm names (inventory) have to
  match hard drive file names, without the file extension (.qcow2)

# more information
Either vms-wokers and vms-masters can be missing or empty, in which case
no vms of that type are managed. VMs are treated differently if they are
workers or masters, so having two lists is the current simple method to
tell them apart.
