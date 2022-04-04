#!/bin/bash

echo "Test custom.sh"
rm -rf feeds/packages/kernel/antfs
rm -rf package/feeds/packages/antfs-mount
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ntfs3-mount feeds/packages/kernel/ntfs3-mount
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ntfs3-oot   feeds/packages/kernel/ntfs3-oot
git clone https://github.com/jerrykuku/luci-app-jd-dailybonus.git   package/luci-app-jd-dailybonus
git clone https://github.com/tty228/luci-app-serverchan.git       package/luci-app-serverchan
git clone https://github.com/destan19/OpenAppFilter.git             package/diy/OpenAppFilter
git clone https://github.com/xiaorouji/openwrt-passwall.git -b packages      package/diy/packages
git clone https://github.com/xiaorouji/openwrt-passwall.git -b luci     package/diy/passwall
git clone https://github.com/vernesong/OpenClash.git                package/diy/openclash
