#!/bin/bash
# custom.sh - OpenWrt 自定义脚本
# 1. 修复 Rust CI 编译问题
# 2. 修改默认网络配置
# 适用于直接在 openwrt 根目录下执行

echo "=============================="
echo "Apply custom.sh"
echo "OpenWrt dir: $(pwd)"
echo "=============================="

# ---------------------------
# 1. Rust CI patch
# ---------------------------
echo "Applying Rust CI patch..."
mkdir -p feeds/packages/lang/rust/patches
cat > feeds/packages/lang/rust/patches/010-disable-ci-llvm.patch <<'EOF'
--- a/src/bootstrap/config.toml.example
+++ b/src/bootstrap/config.toml.example
@@ -146,7 +146,7 @@
-# download-ci-llvm = true
+download-ci-llvm = "if-unchanged"
EOF

# 确认 patch 已生成
grep -R "download-ci-llvm" feeds/packages/lang/rust || echo "Rust patch applied."

# ---------------------------
# 2. Rust Makefile fix
# ---------------------------
if [ -f "feeds/packages/lang/rust/Makefile" ]; then
    echo "Fixing Rust Makefile for CI..."
    sed -i 's/download-ci-llvm=true/download-ci-llvm=false/g' "feeds/packages/lang/rust/Makefile"
else
    echo "Rust Makefile not found: feeds/packages/lang/rust/Makefile"
fi

# ---------------------------
# 3. 修改默认网络配置
# ---------------------------
CONFIG_FILE="package/base-files/files/bin/config_generate"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE 不存在！"
else
    echo "修改默认 IP、网关和 DNS..."

    # 修改默认 IP 地址
    sed -i 's/192\.168\.1\.1/10.10.10.10/g' "$CONFIG_FILE"

    # 修改默认网关
    sed -i 's/192\.168\.1\.1/10.10.10.1/g' "$CONFIG_FILE"

    # 添加默认 DNS
    sed -i '/ipaddr=10.10.10.10/a\        uci set network.lan.dns=10.10.10.10' "$CONFIG_FILE"

    echo "网络配置修改完成."
fi

echo "custom.sh done."
