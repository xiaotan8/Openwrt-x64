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
# 恢复 include/package-pack.mk 到提交前版本
# ==============================
restore_package_pack_mk() {
    echo "[INFO] Restoring include/package-pack.mk to pre-18029977 version"
    
    PACKAGE_PACK_MK="include/package-pack.mk"
    PARENT_COMMIT="095151b2354752be6b4be81e6b22b65227c59746"
    
    if [ -f "$PACKAGE_PACK_MK" ]; then
        # 从parent commit获取文件
        if curl -s -f -o "$PACKAGE_PACK_MK" \
            "https://raw.githubusercontent.com/openwrt/openwrt/$PARENT_COMMIT/$PACKAGE_PACK_MK"; then
            echo "[OK] Successfully restored $PACKAGE_PACK_MK from parent commit ✅"
        else
            echo "[WARN] Failed to download $PACKAGE_PACK_MK from parent commit"
            echo "[INFO] Trying alternative method..."
            
            # 备选方案：使用git cherry-pick恢复
            if git log --oneline | grep -q "18029977"; then
                echo "[INFO] Found the problematic commit in history"
                git show $PARENT_COMMIT:$PACKAGE_PACK_MK > "$PACKAGE_PACK_MK" 2>/dev/null && \
                    echo "[OK] Restored using git show" || echo "[WARN] Git show failed"
            fi
        fi
    else
        echo "[WARN] $PACKAGE_PACK_MK not found, skipping restore"
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
restore_package_pack_mk
fix_rust_compile_error
fix_config_generate
set_default_language_zh_cn

echo "=============================="
echo "custom.sh done."
echo "=============================="
