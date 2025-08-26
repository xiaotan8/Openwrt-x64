#!/bin/bash
set -e

# ==============================
# OpenWrt Custom Script
# ==============================
echo "=============================="
echo "Apply custom.sh"
echo "=============================="

# 定义路径（不加 openwrt/ 前缀）
RUST_MAKEFILE="feeds/packages/lang/rust/Makefile"
CONFIG_GENERATE="package/base-files/files/bin/config_generate"

# 修复 Rust 编译错误（禁用下载 ci-llvm）
fix_rust_compile_error() {
    if [ -f "$RUST_MAKEFILE" ]; then
        echo "[INFO] Fixing Rust Makefile (disable download-ci-llvm)"
        sed -i 's/download-ci-llvm=true/download-ci-llvm=false/g' "$RUST_MAKEFILE"
        grep -R "download-ci-llvm" feeds/packages/lang/rust || true
    else
        echo "[WARN] Rust Makefile not found: $RUST_MAKEFILE"
    fi
}

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
}

# 执行
fix_rust_compile_error
fix_config_generate

echo "=============================="
echo "custom.sh done."
echo "=============================="
