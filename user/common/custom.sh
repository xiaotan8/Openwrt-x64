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
# 7. 修复 boost-system 已删除的问题
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
# 8. 修复 sstp-client 与 ppp 冲突
# ==============================
fix_sstp_conflict() {
    echo "[Step] 修复 sstp-client 与 ppp 冲突..."
    
    # 方法1: 修改 sstp-client 的 Makefile，移除冲突文件
    SSTP_MAKEFILE="feeds/packages/net/sstp-client/Makefile"
    if [ -f "$SSTP_MAKEFILE" ]; then
        echo "  -> 修改 sstp-client Makefile"
        # 移除 chap-secrets 文件的安装
        sed -i '/$(INSTALL_DIR) $(1)\/etc\/ppp\/ip-up.d/d' "$SSTP_MAKEFILE" || true
        sed -i '/$(INSTALL_DIR) $(1)\/etc\/ppp\/ip-down.d/d' "$SSTP_MAKEFILE" || true
        sed -i '/chap-secrets/d' "$SSTP_MAKEFILE" || true
    fi
    
    # 方法2: 创建补丁文件来处理冲突
    SSTP_PATCH_DIR="package/feeds/packages/sstp-client/patches"
    mkdir -p "$SSTP_PATCH_DIR"
    cat > "$SSTP_PATCH_DIR/100-remove-chap-secrets.patch" << 'EOF'
--- a/Makefile
+++ b/Makefile
@@ -50,8 +50,6 @@ define Package/sstp-client/install
 	$(INSTALL_BIN) $(PKG_BUILD_DIR)/sstpc $(1)/usr/sbin/sstpc
 	$(INSTALL_DIR) $(1)/usr/lib/pppd/$(PKG_VERSION)
 	$(INSTALL_BIN) $(PKG_BUILD_DIR)/libsstp-api.so $(1)/usr/lib/pppd/$(PKG_VERSION)/libsstp-api.so
-	$(INSTALL_DIR) $(1)/etc/ppp
-	$(INSTALL_CONF) ./files/chap-secrets $(1)/etc/ppp/chap-secrets
 endef
 
 define Package/sstp-client/conffiles
EOF
}
fix_sstp_conflict

# ==============================
# 9. 修复 vpnc 编译问题
# ==============================
fix_vpnc_issue() {
    echo "[Step] 修复 vpnc 编译问题..."
    VPNC_MAKEFILE="feeds/packages/net/vpnc/Makefile"
    if [ -f "$VPNC_MAKEFILE" ]; then
        echo "  -> 修复 vpnc Makefile"
        sed -i 's/mkdir $(PKG_BUILD_DIR)\/bin/mkdir -p $(PKG_BUILD_DIR)\/bin/' "$VPNC_MAKEFILE"
    fi
}
fix_vpnc_issue

# ==============================
# 10. 更新 feeds
# ==============================
./scripts/feeds update -a
./scripts/feeds install -a

# ==============================
# 11. 最后再次检查 sstp-client 冲突
# ==============================
final_check() {
    echo "[Step] 最终检查 sstp-client 配置..."
    SSTP_MAKEFILE="feeds/packages/net/sstp-client/Makefile"
    if [ -f "$SSTP_MAKEFILE" ]; then
        if grep -q "chap-secrets" "$SSTP_MAKEFILE"; then
            echo "  ⚠️  警告: sstp-client 仍然包含 chap-secrets，尝试再次修复"
            sed -i '/chap-secrets/d' "$SSTP_MAKEFILE"
        else
            echo "  ✅ sstp-client 冲突已修复"
        fi
    fi
}
final_check

echo ">>> custom.sh 执行完成 ✅"
