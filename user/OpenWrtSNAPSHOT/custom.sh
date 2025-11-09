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

# ==============================
# 修复 open-vm-tools 编译错误（禁用 -Werror）
# ==============================
fix_open_vm_tools_build() {
    OPEN_VM_TOOLS_MK="feeds/packages/utils/open-vm-tools/Makefile"

    if [ -f "$OPEN_VM_TOOLS_MK" ]; then
        echo "[INFO] Found open-vm-tools Makefile: $OPEN_VM_TOOLS_MK"
        echo "[INFO] 注入自定义 Build/Compile 段，禁用 -Werror"

        if ! grep -q "Wno-error" "$OPEN_VM_TOOLS_MK"; then
            cat >> "$OPEN_VM_TOOLS_MK" <<'EOF'

# =============================
# Custom fix injected by custom.sh
# GCC14 fix: disable -Werror to allow build to pass
# =============================
define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CFLAGS="$(TARGET_CFLAGS) -Wno-error -Wno-error=format-security" \
		CXXFLAGS="$(TARGET_CFLAGS) -Wno-error -Wno-error=format-security" \
		LDFLAGS="$(TARGET_LDFLAGS)" all
endef
EOF
            echo "[OK] 已成功写入 open-vm-tools 补丁 ✅"
        else
            echo "[SKIP] open-vm-tools Makefile 已存在补丁，跳过注入。"
        fi
    else
        echo "[WARN] open-vm-tools Makefile 未找到，可能 feeds 尚未更新。"
    fi
}

# ==============================
# 修复 libwebsockets CMake Policy 错误（推荐方案：修改 Makefile 而非补丁源码）
# ==============================
fix_libwebsockets_cmake() {
    LWS_MAKEFILE="feeds/packages/libs/libwebsockets/Makefile"

    if [ -f "$LWS_MAKEFILE" ]; then
        echo "[INFO] 修复 libwebsockets 编译参数加入 CMAKE_POLICY_VERSION_MINIMUM"

        # 检查是否已添加过
        if ! grep -q "CMAKE_POLICY_VERSION_MINIMUM" "$LWS_MAKEFILE"; then
            sed -i '/CMAKE_OPTIONS +=/a\  CMAKE_OPTIONS += -DCMAKE_POLICY_VERSION_MINIMUM=3.10' "$LWS_MAKEFILE"
            echo "[OK] 已注入 CMAKE_POLICY_VERSION_MINIMUM ✅"
        else
            echo "[SKIP] 已存在该设置，跳过。"
        fi
    else
        echo "[WARN] 未找到 libwebsockets Makefile（feeds 未更新？）"
    fi
}

# ==============================
# 执行顺序
# ==============================
fix_rust_compile_error
fix_config_generate
set_default_language_zh_cn
fix_open_vm_tools_build
fix_libwebsockets_cmake
