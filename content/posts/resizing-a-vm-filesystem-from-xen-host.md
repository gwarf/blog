---
title = "Resizing a VM filesystem from Xen host"
date = "2014-02-26"
slug = "2014/02/26/resizing-a-vm-filesystem-from-xen-host"
tags =
  - xen
  - vm
---

## Resizing the disk and filesystem of a VM

I had to add more disk space to a Virtual Machine running under
XenServer 6.0. In such situation I ususally do like this:

- create a snapshot (if possible, sometimes disk space makes it
  impossible)
- increase the virtual disk size using XenCenter (running from a Windows
  Virtual Machine...)
- boot Sysrescuecd and resize the filesystem using gparted

But this time, due to some known and unknown magic particular things (VT
extensions disabled, ISO library avaialble on a remote NFS share with latency
problems... I wasn't able to boot sysrescuecd (nor other recent Live CD I
tried), so one of my last option was to attach the VM's virtual disk on the
xen host (another VM could have been used too), here are the steps:

- Find xen host uuid
- Find VM uuid
- Find VM's disk VDI uuid
- Create a new VBD for the xen host to plug the VDI in
- Stop the VM
- Plug the VBD
- Resize the partition and filesystem
- unplug and destroy the VBD
- Restart the VM

### Hands-on

From the xenserver shell:

``` sh Finding the Xen host uuid
hostuuid=$(xe vm-list name-label='Control domain on host: xenserver-XXX' \
  | awk '/uuid/ {print $5}')
xe vm-list uuid=$hostuuid
```

``` sh Finding VM uuid
vmuuid=$(xe vm-list name-label=xxx.domain.tld | awk '/uuid/ {print $5}')
xe vm-list uuid=$vmuuid
```

``` sh Finding VDI uuid (check labels, userdevice number)
xe vm-disk-list uuid=$vmuuid
vdiuuid=xxxx-xxxx-xxx-xxx-xxxx
xe vbd-list vdi-uuid=$vdiuuid
```

``` sh Creating a VBD for the Xen host to plug the VDI in
vbduuid=$(xe vbd-create device=0 vm-uuid=$hostuuid vdi-uuid=$vdiuuid \
  bootable=false mode=RW type=Disk)
xe vbd-list vdi-uuid=$vdiuuid
```

``` sh Plugging the VBD into the Xen host
xe vbd-plug uuid=$vbduuid
xe vbd-list vdi-uuid=$vdiuuid
```

Now the virtual disk of the VM is seen as a local device (/dev/xvda) on
the xen host, it can be accessed using the standard fdisk, parted, mount
tools.

At first I tried to use parted's
[resize](https://www.gnu.org/software/parted/manual/html_chapter/parted_toc.html#TOC25)
command but it didn't work, so I add to delete and recreate the
partition manually according to the cylinders.
(be sure to save the layout of the partitions before messing with
them...)
(and using tmux is highly recommended for such tasks.)

``` sh Resizing the partition using parted
parted /dev/xvda                                                                                                                                [86/818]
GNU Parted 1.8.1
Using /dev/xvda
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) unit s                                                           
(parted) print                                                            

Model: Xen Virtual Block Device (xvd)
Disk /dev/xvda: 83886079s
Sector size (logical/physical): 512B/512B
Partition Table: msdos

Number  Start  End        Size       Type     File system  Flags
 1      2048s  15988735s  15986688s  primary  ext3         boot 

(parted) rm 1                                                             
(parted) mkpart
Partition type?  primary/extended? primary
File system type?  [ext2]? ext3                                           
Start? 2048s
End? 83886078s
(parted) print                                                            

Model: Xen Virtual Block Device (xvd)
Disk /dev/xvda: 83886079s
Sector size (logical/physical): 512B/512B
Partition Table: msdos

Number  Start  End        Size       Type     File system  Flags
 1      2048s  83886078s  83884031s  primary  ext3              

(parted) toggle 1 boot
(parted) print

Model: Xen Virtual Block Device (xvd)
Disk /dev/xvda: 83886079s
Sector size (logical/physical): 512B/512B
Partition Table: msdos

Number  Start  End        Size       Type     File system  Flags
 1      2048s  83886078s  83884031s  primary  ext3         boot 

(parted) quit                                                             
Information: Don't forget to update /etc/fstab, if necessary.
```

``` sh Resizing the filesystem using resize2fs
resize2fs /dev/xvda1    
resize2fs 1.39 (29-May-2006)
Resizing the filesystem on /dev/xvda1 to 10485503 (4k) blocks.
The filesystem on /dev/xvda1 is now 10485503 blocks long

fsck.ext3 -f /dev/xvda1
e2fsck 1.39 (29-May-2006)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/xvda1: 144207/2621440 files (3.3% non-contiguous), 1506575/10485503 blocks
```

``` sh Unplugging the VBD
xe vbd-unplug uuid=$vbduuid
xe vbd-destroy uuid=$vbduuid
xe vbd-list vdi-uuid=$vdiuuid
```

Done, the VM can now be restarted!
