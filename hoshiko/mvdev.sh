#!/usr/bin/bash
adbBinPATH=adb.exe
stuffsToPush=(
    "./hoshiko-cli/build/hoshiko-alya"
    "./hoshiko-cli/build/hoshiko-yuki"
)
defPathToPush="/data/local/tmp"
targetPath="/data/adb/Re-Malwack"
# PUSH FILES TO THE DEVICE
for i in "${stuffsToPush[@]}"; do
    echo "Pushing $i to $defPathToPush..."
    $adbBinPATH push "$i" "$defPathToPush"
done
# SETUP ON DEVICE
$adbBinPATH shell "for i in $defPathToPush/hoshiko-alya $defPathToPush/hoshiko-yuki; do \
    su -c \"cp \$i $targetPath/\"; \
    su -c \"chown 0:0 $targetPath/\$(basename \$i)\"; \
    su -c \"chmod 0755 $targetPath/\$(basename \$i)\"; \
done"