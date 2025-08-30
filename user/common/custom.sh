#!/bin/bash
set -e

echo ">>> Running custom.sh ..."

# ==============================
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
# 3. 拉取常用插件
# ==============================
git clone --depth=1 https://github.com/vernesong/OpenClash.git package/openclash
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages.git package/passwall-packages
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall.git package/passwall-luci

git clone --depth=1 https://github.com/xiaotan8/vlmcsd.git package/vlmcsd
git clone --depth=1 https://github.com/xiaotan8/luci-app-vlmcsd.git package/applications/luci-app-vlmcsd
git clone --depth=1 https://github.com/xiaotan8/wrtbwmon.git package/wrtbwmon

git clone --depth=1 https://github.com/tty228/luci-app-wechatpush.git package/applications/luci-app-wechatpush
git clone --depth=1 https://github.com/KFERMercer/luci-app-tcpdump.git package/applications/luci-app-tcpdump
git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-nikki.git package/applications/luci-app-nikki
git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-momo.git package/applications/luci-app-momo
git clone --depth=1 https://github.com/xiaotan8/luci-app-accesscontrol.git package/applications/luci-app-accesscontrol

# ==============================
# 4. 修复 boost-system 已删除问题
# ==============================
fix_boost_dependency() {
    echo "[Step] 修复 boost-system 依赖问题"
    TARGET_MAKEFILES=$(grep -rl "+boost-system" package/feeds || true)
    for mk in $TARGET_MAKEFILES; do
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
./scripts/feeds update -a
./scripts/feeds install -a

echo ">>> custom.sh 执行完成 ✅"
