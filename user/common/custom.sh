#!/bin/bash
echo "Test custom.sh"

# 删除原 feeds 里相关的包，避免冲突
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}

# 拉取 passwall 相关依赖
git clone https://github.com/xiaorouji/openwrt-passwall-packages package/passwall-packages

# 删除旧的 luci-app-passwall / passwall2 / nikki / OpenClash
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/luci/applications/luci-app-passwall2
rm -rf feeds/luci/applications/luci-app-nikki
rm -rf feeds/luci/applications/luci-app-OpenClash

# 拉取 passwall luci
git clone https://github.com/xiaorouji/openwrt-passwall package/passwall-luci

# 拉取 OpenClash
git clone --depth=1 https://github.com/vernesong/OpenClash.git -b master package/openclash

# 替换主题 argon
rm -rf feeds/luci/themes/luci-theme-argon
git clone https://github.com/jerrykuku/luci-theme-argon.git feeds/luci/themes/luci-theme-argon

# # smartdns（如需启用取消注释）
# rm -rf feeds/packages/net/smartdns
# git clone https://github.com/pymumu/openwrt-smartdns.git feeds/packages/net/smartdns/
# rm -rf feeds/luci/applications/luci-app-smartdns
# git clone https://github.com/pymumu/luci-app-smartdns.git package/applications/luci-app-smartdns

# 拉取实用插件
git clone https://github.com/tty228/luci-app-wechatpush.git     package/applications/luci-app-wechatpush
#git clone https://github.com/rufengsuixing/luci-app-adguardhome.git         package/applications/luci-app-adguardhome
#git clone https://github.com/destan19/OpenAppFilter.git                     package/applications/OpenAppFilter
git clone https://github.com/KFERMercer/luci-app-tcpdump.git                 package/applications/luci-app-tcpdump
git clone https://github.com/nikkinikki-org/OpenWrt-nikki.git                package/applications/OpenWrt-nikki
git clone https://github.com/jerrykuku/luci-app-argon-config.git             package/applications/luci-app-argon-config

# wrtbwmon 流量统计
git clone https://github.com/brvphoenix/wrtbwmon.git package/wrtbwmon
rm -rf package/passwall-packages/trojan-plus
# 更新并安装 feeds，保证能被 make menuconfig 找到
./scripts/feeds update -a
./scripts/feeds install -a
