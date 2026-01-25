#!/bin/bash
set -e

echo "=============================="
echo ">>> Running custom.sh ..."
echo "=============================="

# 1. 删除冲突或旧包
# ==============================
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf package/luci-theme-argon
rm -rf package/applications/luci-app-argon-config
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
# ==============================
# 2. 拉取主题 & 配置插件
# ==============================
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon || {
    echo "[ERROR] luci-theme-argon 拉取失败 ❌"; exit 1;
}
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config.git package/applications/luci-app-argon-config || {
    echo "[ERROR] luci-app-argon-config 拉取失败 ❌"; exit 1;
}

# ==============================
# 3. 克隆插件
# ==============================
echo "[Step] 克隆插件 ..."

# OpenClash
git clone --depth=1 https://github.com/vernesong/OpenClash.git -b master package/openclash

# Passwall
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/passwall-packages
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall package/passwall-luci



# 常用插件
git clone --depth=1 https://github.com/tty228/luci-app-wechatpush.git package/applications/luci-app-wechatpush
git clone --depth=1 https://github.com/KFERMercer/luci-app-tcpdump.git package/applications/luci-app-tcpdump
git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-nikki.git package/applications/luci-app-nikki
git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-momo.git  package/applications/luci-app-momo

# 其它插件
git clone --depth=1 https://github.com/xiaotan8/luci-app-vlmcsd.git package/applications/luci-app-vlmcsd
git clone --depth=1 https://github.com/sirpdboy/luci-app-timecontrol.git package/applications/luci-app-timecontrol
git clone --depth=1 https://github.com/sirpdboy/luci-app-partexp.git  package/applications/luci-app-partexp
git clone --depth=1 https://github.com/sirpdboy/luci-app-netspeedtest.git package/applications/luci-app-netspeedtest
git clone --depth=1 https://github.com/xiaotan8/vlmcsd.git package/vlmcsd
git clone --depth=1 https://github.com/xiaotan8/wrtbwmon.git package/wrtbwmon

# ==============================
# 3. 修复 boost-system 已删除的问题
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
            sed -i 's/\+boost-system/+boost/g' "$mk"
        fi
    done
}
fix_boost_dependency


# ==============================
# 5. 更新 feeds
# ==============================
# ./scripts/feeds update -a
# ./scripts/feeds install -a

echo "=============================="
echo ">>> custom.sh done ✅"
echo "=============================="
