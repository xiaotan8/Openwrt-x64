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
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages package/passwall-packages
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall package/passwall-luci



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
# 4. 修复 shadowsocksr-libev 编译问题
# ==============================
fix_ssr_build() {
    echo "[Step] 修复 shadowsocksr-libev 编译问题"

    SSR_DIR="package/passwall-packages/shadowsocksr-libev"
    if [ -d "$SSR_DIR" ]; then
        echo "  -> 替换为 Lede 版本"
        rm -rf "$SSR_DIR"
        git clone --depth=1 https://github.com/coolsnowwolf/lede.git tmp_lede
        if [ -d tmp_lede/package/lean/shadowsocksr-libev ]; then
            mv tmp_lede/package/lean/shadowsocksr-libev package/passwall-packages/
            echo "  -> 已成功替换为 Lede 版本 ✅"
        else
            echo "  -> Lede 包未找到，使用 -Wno-error 修复"
            local SSR_MK="$SSR_DIR/Makefile"
            if [ -f "$SSR_MK" ]; then
                sed -i '/Build\/Configure/a\ \tCFLAGS+=" -Wno-error"' "$SSR_MK"
                echo "  -> 已添加 -Wno-error ✅"
            fi
        fi
        rm -rf tmp_lede
    else
        echo "  -> 未找到 shadowsocksr-libev，跳过"
    fi
}
fix_ssr_build

# ------------------------------
# 5. 修复 Rust 构建（删除 .orig）
# ------------------------------
fix_rust_vendor() {
    echo "[Step] 清理 Rust vendor 目录里的 .orig 文件"
    find openwrt/build_dir/target-*/rustc-*/vendor -name "*.orig" -delete || true
}
fix_rust_vendor

# ==============================
# 6. 更新 feeds
# ==============================
./scripts/feeds update -a
./scripts/feeds install -a

echo "=============================="
echo ">>> custom.sh done ✅"
echo "=============================="
