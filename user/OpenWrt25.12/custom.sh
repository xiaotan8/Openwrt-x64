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
# 应用 PR #21288 补丁 - 修复 ca-bundle 和 ca-certificates 冲突
# ==============================
apply_pr21288_patch() {
    echo "[INFO] Applying PR #21288 patch to fix ca-bundle/ca-certificates conflict"
    
    # 方案A: 使用git cherry-pick从官方应用（推荐）
    git remote add upstream https://github.com/openwrt/openwrt.git 2>/dev/null || true
    git fetch upstream pull/21288/head:pr-21288 2>/dev/null || true
    
    if git rev-parse --verify pr-21288 >/dev/null 2>&1; then
        echo "[INFO] Found PR #21288 branch, applying commits..."
        # 应用7个关键commit
        git cherry-pick da44bd045f2e2e04d9f540f4824118b25295cd20 || echo "[WARN] da44bd0 already applied or conflicts"
        git cherry-pick 21be7558eb33209390a2c98f7a74b61b3a450cab || echo "[WARN] 21be755 already applied or conflicts"
        git cherry-pick bfafeb93a4faefb76d31c97887e6efe609b45065 || echo "[WARN] bfafeb9 already applied or conflicts"
        git cherry-pick 0b17000c230f569b28597a69c3dd46d4f8caaef3 || echo "[WARN] 0b17000 already applied or conflicts"
        git cherry-pick b0943f91ab48c67bc2530078ed558daf991d9849 || echo "[WARN] b0943f9 already applied or conflicts"
        git cherry-pick a8917e9de91b037c978c679471359ff57eff5ca1 || echo "[WARN] a8917e9 already applied or conflicts"
        git cherry-pick a221d075890d127ddbf49d11f67227bdaca7349b || echo "[WARN] a221d07 already applied or conflicts"
        echo "[OK] PR #21288 commits applied ✅"
    else
        echo "[WARN] PR #21288 branch not found, skipping patch application"
    fi
}

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

# ==============================
# 执行
# ==============================
apply_pr21288_patch
fix_rust_compile_error
fix_config_generate
set_default_language_zh_cn

echo "=============================="
echo "custom.sh done."
echo "=============================="
