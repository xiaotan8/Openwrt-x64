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

    # 确保 feeds 已经有中文语言包
    ./scripts/feeds update luci >/dev/null 2>&1
    ./scripts/feeds install -a >/dev/null 2>&1

    # 在 config_generate 里加入语言设置
    if [ -f "$CONFIG_GENERATE" ]; then
        if ! grep -q "uci set luci.main.lang=zh_cn" "$CONFIG_GENERATE"; then
            echo "[INFO] 注入中文语言设置"
            sed -i '/uci commit system/a\        uci set luci.main.lang=zh_cn\n        uci commit luci' "$CONFIG_GENERATE"
        fi
    fi

    # 加入默认选中 luci-i18n-base-zh-cn
    if ! grep -q "CONFIG_PACKAGE_luci-i18n-base-zh-cn=y" .config 2>/dev/null; then
        echo "CONFIG_PACKAGE_luci-i18n-base-zh-cn=y" >> .config
    fi
}


echo "=============================="
echo ">>> Running OpenWrtSNAPSHOT/custom.sh ..."
echo "=============================="

apply_pr_21288_remote() {
    echo "[Step] Apply PR 21288 patch from GitHub (virtual provides / ca-certs) ..."

    PR_URL="https://github.com/openwrt/openwrt/pull/21288.patch"
    TMP_PATCH="/tmp/openwrt-pr-21288.patch"

    # 下载 patch
    if ! curl -fsSL "$PR_URL" -o "$TMP_PATCH"; then
        echo "  -> 下载 PR 21288 失败，跳过应用该补丁"
        return 0
    fi

    # 预检查
    if patch -p1 --forward --dry-run < "$TMP_PATCH" >/dev/null 2>&1; then
        echo "  -> 预检查通过，开始应用补丁 (patch -p1)"
        patch -p1 --forward < "$TMP_PATCH"
        echo "  -> 已应用 PR 21288 补丁 ✅"
    else
        echo "  -> 补丁似乎已经应用或不适用当前源码，跳过"
    fi

    rm -f "$TMP_PATCH"
}

apply_pr_21288_remote

# ==============================
# 执行
# ==============================
fix_rust_compile_error
fix_config_generate
set_default_language_zh_cn

echo "=============================="
echo "custom.sh done."
echo "=============================="
