#!/bin/bash
# ================================================
# OpenWrt custom.sh 扩展脚本
# ================================================

set -e

echo ">>> Running custom.sh ..."

# ==============================
# 1. 清理 feeds 里自带的包
# ==============================
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
rm -rf feeds/luci/applications/{luci-app-passwall,luci-app-passwall2,luci-app-nikki,luci-app-OpenClash}
rm -rf feeds/luci/themes/luci-theme-argon

# ==============================
# 2. 拉取 passwall / passwall2
# ==============================
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages package/passwall-packages
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall package/passwall-luci
rm -rf package/passwall-packages/trojan-plus
# ==============================
# 3. OpenClash
# ==============================
# git clone --depth=1 https://github.com/vernesong/OpenClash.git -b master package/openclash

# ==============================
# 4. Argon 主题 + 配置插件
# ==============================
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git feeds/luci/themes/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config.git package/applications/luci-app-argon-config

# ==============================
# 5. 常用插件
# ==============================
git clone --depth=1 https://github.com/tty228/luci-app-wechatpush.git package/applications/luci-app-wechatpush
git clone --depth=1 https://github.com/KFERMercer/luci-app-tcpdump.git package/applications/luci-app-tcpdump
git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-nikki.git package/applications/luci-app-nikki
git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-momo.git  package/applications/luci-app-momo
# ==============================
# 6. 可选插件
# ==============================
# git clone --depth=1 https://github.com/pymumu/openwrt-smartdns.git feeds/packages/net/smartdns
# git clone --depth=1 https://github.com/pymumu/luci-app-smartdns.git package/applications/luci-app-smartdns
# git clone --depth=1 https://github.com/rufengsuixing/luci-app-adguardhome.git package/applications/luci-app-adguardhome

git clone --depth=1 https://github.com/xiaotan8/luci-app-vlmcsd.git package/applications/luci-app-vlmcsd
git clone --depth=1 https://github.com/xiaotan8/luci-app-accesscontrol.git package/applications/luci-app-accesscontrol
git clone --depth=1 https://github.com/xiaotan8/vlmcsd.git package/vlmcsd
git clone --depth=1 https://github.com/xiaotan8/wrtbwmon.git package/wrtbwmon


# ==============================
# 9. 修复 boost-system 已删除的问题
# ==============================
fix_boost_dependency() {
    echo "[Step] 修复 boost-system 依赖问题"

    TARGET_MAKEFILES=(
        "package/feeds/packages/domoticz/Makefile"
        "package/feeds/packages/i2pd/Makefile"
        "package/feeds/packages/kea/Makefile"
        "package/feeds/packages/libtorrent-rasterbar/Makefile"
    )

    for mk in "${TARGET_MAKEFILES[@]}"; do
        if [ -f "$mk" ]; then
            echo "  -> 修复 $mk"
            # 替换 +boost-system，无论前后是否有空格
            sed -i 's/\+boost-system/+boost/g' "$mk"
        fi
    done
}
fix_boost_dependency

echo ">>> 修复 sstp-client 与 ppp 冲突..."
sed -i '/chap-secrets/d' package/feeds/packages/sstp-client/Makefile || true
sed -i 's/mkdir $(PKG_BUILD_DIR)\/bin/mkdir -p $(PKG_BUILD_DIR)\/bin/' feeds/packages/net/vpnc/Makefile


# ==============================
# 10. 更新 feeds
# ==============================
./scripts/feeds update -a
./scripts/feeds install -a

echo ">>> custom.sh 执行完成 ✅"
