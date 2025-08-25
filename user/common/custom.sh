#!/bin/bash
# custom.sh - 修复 Rust CI 编译并修改 OpenWrt 默认网络
# 默认 IP: 10.10.10.10
# 默认网关: 10.10.10.1
# 默认 DNS: 10.10.10.10

# OpenWrt 工作目录（根据你的 workflow 或路径调整）
BUILD_DIR="${BUILD_DIR:}"

echo "=============================="
echo "Apply custom.sh"
echo "OpenWrt dir: $BUILD_DIR"
echo "=============================="

# -----------------------------
# 1. 修复 Rust CI 编译问题
# -----------------------------
fix_rust_compile_error() {
    RUST_MAKEFILE="$BUILD_DIR/feeds/packages/lang/rust/Makefile"
    if [ -f "$RUST_MAKEFILE" ]; then
        echo "Fixing Rust CI compile error..."
        # 将 download-ci-llvm=true 改成 false
        sed -i 's/download-ci-llvm=true/download-ci-llvm=false/g' "$RUST_MAKEFILE"
        grep -R "download-ci-llvm" "$BUILD_DIR/feeds/packages/lang/rust"
    else
        echo "Rust Makefile not found: $RUST_MAKEFILE"
    fi
}

fix_rust_compile_error

# -----------------------------
# 2. 修改默认网络设置
# -----------------------------
CONFIG_FILE="$BUILD_DIR/package/base-files/files/bin/config_generate"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE 不存在！"
else
    echo "Modifying default IP, gateway, and DNS..."
    # 修改默认 IP
    sed -i 's/192\.168\.1\.1/10.10.10.10/g' "$CONFIG_FILE"

    # 修改默认网关
    sed -i 's/192\.168\.1\.1/10.10.10.1/g' "$CONFIG_FILE"

    # 修改默认 DNS
    sed -i '/ipaddr=10.10.10.10/a\        uci set network.lan.dns=10.10.10.10' "$CONFIG_FILE"

    echo "Network modification complete."
fi

echo "custom.sh done."
