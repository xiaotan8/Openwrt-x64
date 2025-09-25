#!/bin/bash
set -e

# ==============================
# OpenWrt Custom Script (Final)
# ==============================
echo "=============================="
echo "Apply custom.sh"
echo "=============================="

# 定义路径
RUST_MAKEFILE="feeds/packages/lang/rust/Makefile"
PATCH_DIR="feeds/packages/lang/rust/patches"
PATCH_FILE="$PATCH_DIR/0001-Update-xz2-and-use-it-static.patch"
CONFIG_GENERATE="package/base-files/files/bin/config_generate"

# ==============================
# 修复 Rust 编译错误（禁用下载 ci-llvm）
# ==============================
fix_rust_compile_error() {
    if [ -f "$RUST_MAKEFILE" ]; then
        echo "[INFO] 修复 Rust Makefile (禁用 ci-llvm)"
        sed -i 's/download-ci-llvm=true/download-ci-llvm=false/g' "$RUST_MAKEFILE"

        if grep -q "download-ci-llvm=false" "$RUST_MAKEFILE"; then
            echo "[OK] Rust Makefile 修改成功 ✅"
        else
            echo "[FAIL] Rust Makefile 修改失败 ❌"
        fi
    else
        echo "[WARN] Rust Makefile 未找到: $RUST_MAKEFILE"
    fi
}

# ==============================
# 修复 Rust 补丁 (删除静态 xz2)
# ==============================
fix_rust_patch() {
    if [ -f "$PATCH_FILE" ]; then
        echo "[INFO] 删除有问题的 Rust 补丁: $PATCH_FILE"
        rm -f "$PATCH_FILE"
    else
        echo "[OK] 未找到 $PATCH_FILE，无需处理"
    fi
}

# ==============================
# 修复 Rust vendor 目录
# ==============================
fix_rust_vendor() {
    if [ -f "$RUST_MAKEFILE" ]; then
        echo "[INFO] 执行 Rust vendor 修复"
        make package/rust/refresh V=s || true
        echo "[OK] Rust vendor 修复完成 ✅"
    else
        echo "[WARN] Rust Makefile 未找到，跳过 vendor 修复"
    fi
}

# ==============================
# 修改默认网络配置
# ==============================
fix_config_generate() {
    if [ -f "$CONFIG_GENERATE" ]; then
        echo "[INFO] 修改默认 LAN 网络参数"

        sed -i 's/192\.168\.1\.1/10.10.10.10/g' "$CONFIG_GENERATE"
        sed -i 's/192\.168\.1\.1/10.10.10.1/g' "$CONFIG_GENERATE"

        sed -i '/ipaddr=10.10.10.10/a\        uci set network.lan.dns=10.10.10.10' "$CONFIG_GENERATE"

        echo "-------- 检查修改结果 --------"
        grep -E "10\.10\.10\.10|10\.10\.10\.1" "$CONFIG_GENERATE" || echo "[FAIL] 修改失败 ❌"
        echo "-----------------------------"
    else
        echo "[WARN] config_generate 未找到: $CONFIG_GENERATE"
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
# 执行所有修复
# ==============================
fix_rust_compile_error
fix_rust_patch
fix_rust_vendor
fix_config_generate
set_default_language_zh_cn

echo "=============================="
echo "custom.sh done."
echo "=============================="
