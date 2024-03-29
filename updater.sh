#!/bin/bash
#
# Import or update qcacld-3.0, qca-wifi-host-cmn, fw-api and audio-kernel.
#

read -p "Please input the tag/branch name: " branch
read -p "What do you want to do (import (i) or update (u)): " option

case $option in
    import | i)
 #       git subtree add --prefix=techpack/camera https://git.codelinaro.org/clo/la/platform/vendor/opensource/camera-kernel/ $branch
 #       git subtree add --prefix=techpack/display https://git.codelinaro.org/clo/la/platform/vendor/opensource/display-drivers/ $branch
 #       git subtree add --prefix=techpack/video https://git.codelinaro.org/clo/la/platform/vendor/opensource/video-driver/ $branch 
 #       git subtree add --prefix=techpack/dataipa https://git.codelinaro.org/clo/la/platform/vendor/opensource/dataipa/ $branch
 #       git subtree add --prefix=techpack/datarmnet https://git.codelinaro.org/clo/la/platform/vendor/qcom/opensource/datarmnet/ $branch
 #       git subtree add --prefix=techpack/datarmnet-ext https://git.codelinaro.org/clo/la/platform/vendor/qcom/opensource/datarmnet-ext/ $branch
        git subtree add --prefix=techpack/audio https://git.codelinaro.org/clo/la/platform/vendor/opensource/audio-kernel/ $branch
        git subtree add --prefix=drivers/staging/qcacld-3.0 https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/qcacld-3.0 $branch
        git subtree add --prefix=drivers/staging/qca-wifi-host-cmn https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/qca-wifi-host-cmn $branch
        git subtree add --prefix=drivers/staging/fw-api https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/fw-api $branch
        echo "Done."
        ;;
    update | u)
        git subtree pull --prefix=drivers/staging/qcacld-3.0 https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/qcacld-3.0 $branch
        git subtree pull --prefix=drivers/staging/qca-wifi-host-cmn https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/qca-wifi-host-cmn $branch
        git subtree pull --prefix=drivers/staging/fw-api https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/fw-api $branch
        git subtree pull --prefix=techpack/audio https://git.codelinaro.org/clo/la/platform/vendor/opensource/audio-kernel/ $branch
        echo "Done."
        ;;
    *)
        echo "Invalid character"
        ;;
esac
