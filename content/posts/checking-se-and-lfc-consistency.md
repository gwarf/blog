+++
title = "checking se and lfc consistency"
date = "2014-02-11"
slug = "2014/02/11/checking-se-and-lfc-consistency"
Categories = []
+++
## Dealing with inconsistency between the LFC and DPM
The biomed VO team made accesible some useful tools to enforce
consistency of Storage Elements (SE) and Logical File CAtalog (LFC)
available on [github](https://github.com/frmichel/biomed-support-tools).

In the [neugrid4you project](https://neugrid4you.eu) we have a lot of
[big dataset](https://neugrid4you.eu/datasets) made available to our
user community, but some of the datasets are very big,
([ADNI](https://ida.loni.ucla.edu/login.jsp?project=ADNI) is
something like 30 GiB) and we have to copy and register them in the grid
on multiple SE and register in our LFC.
In order to ensure that there isn't any inconsistency (i.e. in order to
cl ean all the inconsistencies ;) ) 

## Retrieving inconsistencies

The *diff-se-dump-lfc.sh* script is used to find inconsistencies between
a dump of a DPM and of the LFC.

``` sh Dumping the DPNS VO-specific folder
dump-se-files.py \
  --url srm://<dpm_server_name>/dpm/<dpm_domain_name>/home/<vo_name> \
  --output-file <dpm_server_name>-dpm-dump.txt
```

``` sh Dumping the LFC VO-specific folder
export LFC_HOST=<lfc_host>
LFCBrowseSE <dpm_server_name> --vo <vo_name> --sfn > <lfc_host>-<vo_name>-lfc-dump.txt
```

``` sh Searching for inconsistencies for files older than 1 month
diff-se-dump-lfc.sh --older-than 1 \
  --se <dpm_server_name> \
  --se-dump <dpm_server_name>-dpm-dump.txt \
  --lfc-dump <lfc_host>-<vo_name>-lfc-dump.txt
```

The script will report *zombie files*, *ghost entries* and files found
both in the SE and the LFC.

Zombie files are files that exist in the SE but are no more referenced
in the LFC.

Ghost entries are entries in the LFC that have no corresponding files on
the SE.

## Cleaning ghost entries
There is no automatic way of cleaning ghost entries, and in order to
retrieve the corresponding LFN it is required to directly access the LFC
database.

``` sql
SELECT Cns_file_metadata.fileid,guid,name
  FROM Cns_file_metadata
  INNER JOIN Cns_file_replica
  ON Cns_file_metadata.fileid=Cns_file_replica.fileid
  WHERE sfn='srm: //<dpm_server_name>:8446/dpm/<dpm_domain_name>/home/<vo_name>/generated/2014-02-10/file-121aa7e8-a9ec-4401-84f1-24341a74433c';
```

``` sh Script for retrieving the guid of a sfn
#!/bin/sh

set -e

SFN="$1"
DB_NAME=cns_db
QUERY="SELECT guid FROM Cns_file_metadata INNER
JOIN Cns_file_replica
ON Cns_file_metadata.fileid=Cns_file_replica.fileid
WHERE sfn='$SFN'"

GUID=$(mysql --batch --silent "$DB_NAME" -e "$QUERY")

echo "guid:$GUID"

exit 0
```

``` sh
for sfn in $(cat <dpm_server_name>.output_lfc_lost_files); do
  ./get-lfn-for-ghostfile.sh $sfn
done > guid-list.txt
```

``` sh
for guid in $(cat guid-list.txt); do
  lcg-la $guid
done
```

Once the list of lfn has been retrieved it is possible to remove the
wrong entries.

``` sh
% lcg-lr lfn:/grid/<vo_name>/data/ADNI/IMAGES/128_S_4607/ADNI2/nG+ADNI2+128_S_4607+20121109+0847+S174741+3T0+T2ST+ORIG+V01.tar.bz2
srm://<dpm_server_name>/dpm/<dpm_domain_name>/home/<vo_name>/generated/2013-09-20/file7fa6f030-f029-418c-a60c-5a8d04253a68
srm://<dpm2_server_name>/dpm/<dpm2_domain_name>/home/<vo_name>/generated/2013-09-20/file2e44af61-a0e0-4868-af30-d08d9e3a7a69

% lcg-del --force srm://<dpm_server_name>/dpm/<dpm_domain_name>/home/<vo_name>/generated/2013-09-20/file7fa6f030-f029-418c-a60c-5a8d04253a68

% lcg-lr lfn:/grid/<vo_name>/data/ADNI/IMAGES/128_S_4607/ADNI2/nG+ADNI2+128_S_4607+20121109+0847+S174741+3T0+T2ST+ORIG+V01.tar.bz2
srm://<dpm2_server_name>/dpm/<dpm2_domain_name>/home/<vo_name>/generated/2013-09-20/file2e44af61-a0e0-4868-af30-d08d9e3a7a69

% lcg-rep -d <dpm_server_name>
lfn:/grid/<vo_name>/data/ADNI/IMAGES/128_S_4607/ADNI2/nG+ADNI2+128_S_4607+20121109+0847+S174741+3T0+T2ST+ORIG+V01.tar.bz2

% lcg-lr
% lfn:/grid/<vo_name>/data/ADNI/IMAGES/128_S_4607/ADNI2/nG+ADNI2+128_S_4607+20121109+0847+S174741+3T0+T2ST+ORIG+V01.tar.bz2
srm://<dpm_server_name>/dpm/<dpm_domain_name>/home/<vo_name>/generated/2014-02-12/filecb922278-02c3-4642-b085-0f3695c9aaee
srm://<dpm2_server_name>/dpm/<dpm2_domain_name>/home/<vo_name>/generated/2013-09-20/file2e44af61-a0e0-4868-af30-d08d9e3a7a69
```
