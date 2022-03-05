#!/bin/bash

echo "Test custom.sh"
rm -rf package/diy/OpenAppFilter
git clone https://github.com/jerrykuku/luci-app-jd-dailybonus.git package/luci-app-jd-dailybonus
git clone https://github.com/tty228/luci-app-serverchan.git       package/luci-app-serverchan
git clone https://github.com/destan19/OpenAppFilter.git           package/diy/OpenAppFilter
# git clone https://github.com/xiaorouji/openwrt-passwall.git       package/diy/passwall
git clone https://github.com/xiaotan8/openwrt-passwall.git        package/diy/passwall
git clone https://github.com/vernesong/OpenClash.git              package/diy/openclash
