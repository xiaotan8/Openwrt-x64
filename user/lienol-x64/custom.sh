#!/bin/bash

echo "Test custom.sh"
git clone https://github.com/jerrykuku/luci-app-jd-dailybonus.git   package/luci-app-jd-dailybonus
git clone https://github.com/xiaotan8/luci-app-serverchan.git       package/luci-app-serverchan
git clone https://github.com/destan19/OpenAppFilter.git             package/diy/OpenAppFilter
git clone https://github.com/xiaorouji/openwrt-passwall.git -b packages      package/diy/packages
git clone https://github.com/xiaorouji/openwrt-passwall.git -b luci     package/diy/passwall
git clone https://github.com/vernesong/OpenClash.git                package/diy/openclash
git clone https://github.com/messense/aliyundrive-webdav.git        package/diy/aliyundrive-webdav
git clone https://github.com/messense/aliyundrive-fuse.git          package/diy/aliyundrive-fuse
