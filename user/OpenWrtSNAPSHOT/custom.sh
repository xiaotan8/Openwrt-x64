#!/bin/bash
set -e

echo "=============================="
echo "Apply custom.sh"
echo "=============================="

RUST_MAKEFILE="feeds/packages/lang/rust/Makefile"
CONFIG_GENERATE="package/base-files/files/bin/config_generate"
OPEN_VM_TOOLS_MK="feeds/packages/utils/open-vm-tools/Makefile"
LWS_PATCH_DIR="feeds/packages/libs/libwebsockets/patches"
LWS_PATCH_FILE="$LWS_PATCH_DIR/100-no-werror.patch"

# 修复 Rust 编译错误
fix_rust_compile_error() {
    if [ -f "$RUST_MAKEFILE" ]; then
        sed -i 's/download-ci-llvm=true/download-ci-llvm=false/g' "$RUST_MAKEFILE"
        echo "[OK] Rust Makefile 修改完成 ✅"
    fi
}

# 修改默认网络
fix_config_generate() {
    if [ -f "$CONFIG_GENERATE" ]; then
        sed -i 's/192\.168\.1\.1/10.10.10.10/g' "$CONFIG_GENERATE"
        sed -i 's/192\.168\.1\.1/10.10.10.1/g' "$CONFIG_GENERATE"
        sed -i '/ipaddr=10.10.10.10/a\        uci set network.lan.dns=10.10.10.10' "$CONFIG_GENERATE"
        echo "[OK] 默认LAN网络修改完成 ✅"
    fi
}

# 默认语言改中文
set_default_language_zh_cn() {
    ./scripts/feeds update luci >/dev/null 2>&1
    ./scripts/feeds install -a >/dev/null 2>&1

    if [ -f "$CONFIG_GENERATE" ] && ! grep -q "uci set luci.main.lang=zh_cn" "$CONFIG_GENERATE"; then
        sed -i '/uci commit system/a\        uci set luci.main.lang=zh_cn\n        uci commit luci' "$CONFIG_GENERATE"
    fi

    echo "CONFIG_PACKAGE_luci-i18n-base-zh-cn=y" >> .config
    echo "[OK] 默认语言设置为中文 ✅"
}

# 修复 open-vm-tools 编译
fix_open_vm_tools_build() {
    if [ -f "$OPEN_VM_TOOLS_MK" ] && ! grep -q "Wno-error" "$OPEN_VM_TOOLS_MK"; then
        cat >> "$OPEN_VM_TOOLS_MK" <<'EOF'

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CFLAGS="$(TARGET_CFLAGS) -Wno-error" \
		CXXFLAGS="$(TARGET_CFLAGS) -Wno-error" \
		LDFLAGS="$(TARGET_LDFLAGS)" all
endef
EOF
        echo "[OK] open-vm-tools 禁用 -Werror ✅"
    fi
}

# ✅ 新增：修复 libwebsockets 编译 - 禁用 -Werror
fix_libwebsockets_no_werror() {
    mkdir -p "$LWS_PATCH_DIR"
    cat > "$LWS_PATCH_FILE" <<'EOF'
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -155,7 +155,7 @@ if (LWS_WITH_WARNINGS)
        if (CMAKE_COMPILER_IS_GNUCC OR ("${CMAKE_C_COMPILER_ID}" MATCHES "Clang"))
                add_compile_options(
                        -Wall
-                       -Werror
+                       # -Werror disabled for OpenWrt GCC >= 13/14
                        -Wuninitialized
                )
        endif()
EOF

    echo "[OK] 已注入 libwebsockets 补丁：$LWS_PATCH_FILE ✅"
}

# 执行顺序
fix_rust_compile_error
fix_config_generate
set_default_language_zh_cn
fix_open_vm_tools_build
fix_libwebsockets_no_werror

echo "=============================="
echo "custom.sh 执行完毕 ✅"
echo "=============================="
