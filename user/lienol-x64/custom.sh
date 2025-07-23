#!/bin/bash

echo "Test custom.sh"
rm -rf feeds/luci/themes/luci-theme-argon
git clone https://github.com/jerrykuku/luci-theme-argon.git       feeds/luci/themes/luci-theme-argon
git clone https://github.com/tty228/luci-app-wechatpush.git       package/luci-app-wechatpush
git clone https://github.com/destan19/OpenAppFilter.git           package/diy/OpenAppFilter
# git clone https://github.com/xiaorouji/openwrt-passwall.git -b packages      package/diy/passwall-packages
# git clone https://github.com/xiaorouji/openwrt-passwall.git -b luci     package/diy/passwall
# git clone  https://github.com/fw876/helloworld.git                package/helloworld
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
git clone https://github.com/xiaorouji/openwrt-passwall-packages package/passwall-packages
rm -rf feeds/luci/applications/luci-app-openclash
rm -rf feeds/luci/applications/luci-app-passwall
git clone https://github.com/xiaorouji/openwrt-passwall package/passwall-luci
git clone https://github.com/vernesong/OpenClash package/openclash

rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 25.x feeds/packages/lang/golang
