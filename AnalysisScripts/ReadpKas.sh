#!/bin/bash

# The two folloiwng Result.txt files come from
# running for following command 
#
# for cpout in pH*/prod_1.cpout;do
#  cphstats -i ../prep/2C9V_CuCuSiteWT_new.cpin $cpout;
# done | fitpkaeo.py --graph --graph-path fracprot.png
#
# The below commands generate ComparativeResult.txt 
# whcih is read by ChargeCompensation.py to perform
# the charge compensaiton analysis.

OxFile="Oxidized/WT/traj/Result.txt"
RdFile="Reduced/WT/traj/Result.txt"

lc1=$(wc -l $OxFile | awk '{print $1}')
lc2=$(wc -l $RdFile | awk '{print $1}')

rm ComparativeResult.txt 2> /dev/null
if [ $lc1 == $lc2 ];then
  for i in $(seq 1 1 $lc1);do
    res=$(sed "$i!d" $OxFile | awk '{print $1}') 
    num=$(sed "$i!d" $OxFile | awk '{print $2}' | cut -d ':' -f1) 
     ox=$(sed "$i!d" $OxFile | awk '{print $5}') 
    red=$(sed "$i!d" $RdFile | awk '{print $5}')
    diff=$(awk "BEGIN {print ($red - $ox)}")
#   echo -n "$num $res $ox $red"; printf " %.3f \n" $diff

    printf "%d %s %.3f %.3f %.3f \n" $num $res $ox $red $diff 
    printf "%d %s %.3f %.3f %.3f \n" $num $res $ox $red $diff >> ComparativeResult.txt
  done
fi

