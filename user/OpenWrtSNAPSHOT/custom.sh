#!/bin/bash
set -e

# ==============================
# OpenWrt Custom Script
# ==============================
echo "=============================="
echo "Apply custom.sh"
echo "=============================="

# 定义路径
RUST_MAKEFILE="feeds/packages/lang/rust/Makefile"
CONFIG_GENERATE="package/base-files/files/bin/config_generate"
RUST_VENDOR_DIR="build_dir/target-x86_64_musl/host/rustc-1.90.0-src/vendor"

# ==============================
# 修复 Rust 编译错误（禁用下载 ci-llvm）
# ==============================
fix_rust_compile_error() {
    if [ -f "$RUST_MAKEFILE" ]; then
        echo "[INFO] Fixing Rust Makefile (disable download-ci-llvm)"
        sed -i 's/download-ci-llvm=true/download-ci-llvm=false/g' "$RUST_MAKEFILE"

        if grep -q "download-ci-llvm=false" "$RUST_MAKEFILE"; then
            echo "[OK] Rust Makefile 已成功修改 ✅"
        else
            echo "[FAIL] Rust Makefile 修改失败 ❌"
        fi
    else
        echo "[WARN] Rust Makefile not found: $RUST_MAKEFILE"
    fi
}

# ==============================
# 修复 Rust vendor (清理无效的 *.orig 文件)
# ==============================
fix_rust_vendor() {
    if [ -d "$RUST_VENDOR_DIR" ]; then
        echo "[INFO] 清理 Rust vendor 里的 *.orig 文件"
        find "$RUST_VENDOR_DIR" -name "*.orig" -delete
        echo "[OK] 已删除多余的 .orig 文件 ✅"
    else
        echo "[WARN] Rust vendor not found: $RUST_VENDOR_DIR"
    fi
}

# ==============================
# 修改默认网络配置
# ==============================
fix_config_generate() {
    if [ -f "$CONFIG_GENERATE" ]; then
        echo "[INFO] Found config_generate: $CONFIG_GENERATE"
        echo "[INFO] 修改默认 LAN 网络参数"

        sed -i 's/192\.168\.1\.1/10.10.10.10/g' "$CONFIG_GENERATE"
        sed -i 's/192\.168\.1\.1/10.10.10.1/g' "$CONFIG_GENERATE"

        sed -i '/ipaddr=10.10.10.10/a\        uci set network.lan.dns=10.10.10.10' "$CONFIG_GENERATE"

        echo "-------- 检查修改结果 --------"
        grep -E "10\.10\.10\.10|10\.10\.10\.1" "$CONFIG_GENERATE" || echo "[FAIL] 未找到修改结果 ❌"
        echo "-----------------------------"
    else
        echo "[WARN] config_generate not found: $CONFIG_GENERATE"
    fi
}

# ==============================
# 设置默认语言为简体中文
# ==============================
set_default_language_zh_cn() {
    echo "[INFO] 设置默认界面语言为简体中文"

    ./scripts/feeds update luci >/dev/null 2>&1
    ./scripts/feeds install -a >/dev/null 2>&1

    if [ -f "$CONFIG_GENERATE" ]; then
        if ! grep -q "uci set luci.main.lang=zh_cn" "$CONFIG_GENERATE"; then
            echo "[INFO] 注入中文语言设置"
            sed -i '/uci commit system/a\        uci set luci.main.lang=zh_cn\n        uci commit luci' "$CONFIG_GENERATE"
        fi
    fi

    if ! grep -q "CONFIG_PACKAGE_luci-i18n-base-zh-cn=y" .config 2>/dev/null; then
        echo "CONFIG_PACKAGE_luci-i18n-base-zh-cn=y" >> .config
    fi
}

# ==============================
# 执行
# ==============================
fix_rust_compile_error
fix_rust_vendor
fix_config_generate
set_default_language_zh_cn

echo "=============================="
echo "custom.sh done."
echo "=============================="
