#!/bin/bash
# ================================================
# OpenWrt custom.sh 扩展脚本
# ================================================

set -e

echo ">>> Running custom.sh ..."

# ==============================
# 1. 清理 feeds 里自带的包
# ==============================
echo "清理feeds中不需要的包..."
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
rm -rf feeds/luci/applications/{luci-app-passwall,luci-app-passwall2,luci-app-nikki,luci-app-OpenClash}
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf package/feeds/packages/sstp-client
rm -rf package/feeds/packages/net/vpnc
rm -rf feeds/packages/sstp-client
rm -rf feeds/packages/net/vpnc
# ==============================
# 2. 拉取 passwall / passwall2
# ==============================
echo "添加PassWall..."
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages package/passwall-packages
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall package/passwall-luci
rm -rf package/passwall-packages/trojan-plus

# ==============================
# 3. OpenClash
# ==============================
# echo "添加OpenClash..."
# git clone --depth=1 https://github.com/vernesong/OpenClash.git -b master package/openclash

# ==============================
# 4. Argon 主题 + 配置插件
# ==============================
echo "添加Argon主题..."
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git feeds/luci/themes/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config.git package/applications/luci-app-argon-config

# ==============================
# 5. 常用插件
# ==============================
echo "添加常用插件..."
git clone --depth=1 https://github.com/tty228/luci-app-wechatpush.git package/applications/luci-app-wechatpush
git clone --depth=1 https://github.com/KFERMercer/luci-app-tcpdump.git package/applications/luci-app-tcpdump
git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-nikki.git package/applications/luci-app-nikki
git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-momo.git package/applications/luci-app-momo

# ==============================
# 6. 可选插件
# ==============================
# echo "添加可选插件..."
# git clone --depth=1 https://github.com/pymumu/openwrt-smartdns.git feeds/packages/net/smartdns
# git clone --depth=1 https://github.com/pymumu/luci-app-smartdns.git package/applications/luci-app-smartdns
# git clone --depth=1 https://github.com/rufengsuixing/luci-app-adguardhome.git package/applications/luci-app-adguardhome

git clone --depth=1 https://github.com/xiaotan8/luci-app-vlmcsd.git package/applications/luci-app-vlmcsd
git clone --depth=1 https://github.com/xiaotan8/luci-app-accesscontrol.git package/applications/luci-app-accesscontrol
git clone --depth=1 https://github.com/xiaotan8/vlmcsd.git package/vlmcsd
git clone --depth=1 https://github.com/xiaotan8/wrtbwmon.git package/wrtbwmon

# ==============================
# 7. 修复 boost-system 已删除的问题
# ==============================
fix_boost_dependency() {
    echo "修复boost-system依赖问题..."

    TARGET_MAKEFILES=(
        "package/feeds/packages/domoticz/Makefile"
        "package/feeds/packages/i2pd/Makefile"
        "package/feeds/packages/kea/Makefile"
        "package/feeds/packages/libtorrent-rasterbar/Makefile"
    )

    for mk in "${TARGET_MAKEFILES[@]}"; do
        if [ -f "$mk" ]; then
            echo "修复 $mk"
            sed -i 's/\+boost-system/+boost/g' "$mk"
        fi
    done
}
fix_boost_dependency

# ==============================
# 8. 最终检查和清理
# ==============================
final_check() {
    echo "执行最终检查..."
    # 检查是否有重复的包
    if [ -d "package/passwall-packages" ] && [ -d "feeds/packages/net/xray-core" ]; then
        echo "警告: 发现可能的包冲突 (xray-core)"
    fi
    
    # 清理.git目录节省空间
    find . -name ".git" -type d | xargs rm -rf
}
final_check

# ==============================
# 9. 更新 feeds
# ==============================
echo "更新feeds..."
./scripts/feeds update -a
./scripts/feeds install -a

echo ">>> custom.sh 执行完成 ✅"
