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

# ==============================
# 3. OpenClash
# ==============================
git clone --depth=1 https://github.com/vernesong/OpenClash.git -b master package/openclash

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
git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-nikki.git package/applications/OpenWrt-nikki

# ==============================
# 6. 可选插件
# ==============================
# git clone --depth=1 https://github.com/pymumu/openwrt-smartdns.git feeds/packages/net/smartdns
# git clone --depth=1 https://github.com/pymumu/luci-app-smartdns.git package/applications/luci-app-smartdns
# git clone --depth=1 https://github.com/rufengsuixing/luci-app-adguardhome.git package/applications/luci-app-adguardhome

git clone --depth=1 https://github.com/xiaotan8/luci-app-vlmcsd.git package/applications/luci-app-vlmcsd
git clone --depth=1 https://github.com/xiaotan8/luci-app-accesscontrol.git package/applications/luci-app-accesscontrol
git clone --depth=1 https://github.com/cokebar/openwrt-vlmcsd package/vlmcsd
git clone --depth=1 https://github.com/brvphoenix/wrtbwmon package/wrtbwmon

# ==============================
# 7. 覆盖 trojan-plus Makefile
# ==============================
mkdir -p package/passwall-packages/trojan-plus
cat > package/passwall-packages/trojan-plus/Makefile << "EOF"
include $(TOPDIR)/rules.mk

PKG_NAME:=trojan-plus
PKG_VERSION:=10.0.3
PKG_RELEASE:=2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/peter-tank/trojan-plus.git
PKG_SOURCE_DATE:=2020-09-06
PKG_SOURCE_VERSION:=a6394cdd718669b0c7491493a78e61f6f0f899b3
PKG_MIRROR_HASH:=adad9914b2c1cffa0f8c2b10610f7119f77090ae5259872af0b82d2547500100

PKG_BUILD_PARALLEL:=1
PKG_BUILD_DEPENDS:=openssl

PKG_LICENSE:=GPL-3.0
PKG_LICENSE_FILE:=LICENSE
PKG_MAINTAINER:=Trojan-Plus-Group

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

TARGET_CXXFLAGS += -Wall -Wextra
TARGET_CXXFLAGS += $(FPIC)
TARGET_CXXFLAGS += -flto
TARGET_LDFLAGS += -flto
TARGET_CXXFLAGS += -std=c++11
TARGET_CXXFLAGS := $(filter-out -O%,$(TARGET_CXXFLAGS)) -O3
TARGET_CXXFLAGS += -ffunction-sections -fdata-sections
TARGET_LDFLAGS += -Wl,--gc-sections

CMAKE_OPTIONS += \
  -DENABLE_MYSQL=OFF \
  -DENABLE_NAT=ON \
  -DENABLE_REUSE_PORT=ON \
  -DENABLE_SSL_KEYLOG=ON \
  -DENABLE_TLS13_CIPHERSUITES=ON \
  -DFORCE_TCP_FASTOPEN=OFF \
  -DSYSTEMD_SERVICE=OFF \
  -DOPENSSL_USE_STATIC_LIBS=FALSE \
  -DBoost_DEBUG=ON \
  -DBoost_NO_BOOST_CMAKE=ON

define Package/trojan-plus
  SECTION:=net
  CATEGORY:=Network
  TITLE:=An unidentifiable mechanism that helps you bypass GFW. It's compatible with original trojan with experimental features.
  URL:=https://github.com/Trojan-Plus-Group/trojan-plus
  DEPENDS:=+libpthread +libstdcpp +libopenssl +boost +boost-program_options
endef

define Package/trojan-plus/install
  $(INSTALL_DIR) $(1)/usr/sbin
  $(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/trojan $(1)/usr/sbin/trojan-plus
endef

$(eval $(call BuildPackage,trojan-plus))
EOF

# ==============================
# 8. 额外插件补全
# ==============================
echo "[Step] 克隆额外插件"


# ==============================
# 9. 修复 boost-system 已删除的问题
# ==============================
fix_boost_dependency() {
    echo "[Step] 修复 boost-system 依赖问题"
    for mk in $(grep -rl "boost-system" package/feeds || true); do
        echo "  -> 修复 $mk"
        sed -i 's/+boost-system/+boost/g' "$mk"
    done
}
fix_boost_dependency

# ==============================
# 10. 更新 feeds
# ==============================
./scripts/feeds update -a
./scripts/feeds install -a

echo ">>> custom.sh 执行完成 ✅"
