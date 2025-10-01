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
GEN_IMAGE_GENERIC="scripts/gen_image_generic.sh"

# ==============================
# 修复 Rust 编译错误（禁用下载 ci-llvm）
# ==============================
fix_rust_compile_error() {
    if [ -f "$RUST_MAKEFILE" ]; then
        echo "[INFO] Fixing Rust Makefile (disable download-ci-llvm)"
        sed -i 's/download-ci-llvm=true/download-ci-llvm=false/g' "$RUST_MAKEFILE"
    else
        echo "[WARN] Rust Makefile not found: $RUST_MAKEFILE"
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
            sed -i '/uci commit system/a\        uci set luci.main.lang=zh_cn\n        uci commit luci' "$CONFIG_GENERATE"
        fi
    fi

    if ! grep -q "CONFIG_PACKAGE_luci-i18n-base-zh-cn=y" .config 2>/dev/null; then
        echo "CONFIG_PACKAGE_luci-i18n-base-zh-cn=y" >> .config
    fi
}

# ==============================
# 修改 scripts/gen_image_generic.sh (补 EF02 分区)
# ==============================
fix_gen_image_generic() {
    if [ -f "$GEN_IMAGE_GENERIC" ]; then
        echo "[INFO] Patching gen_image_generic.sh for EF02 support"

        if ! grep -q "EFIPARTTYPE" "$GEN_IMAGE_GENERIC"; then
            cat >> "$GEN_IMAGE_GENERIC" <<'EOF'

# ==============================
# Custom: add EF02 partition when using GUID (GPT)
# ==============================
if [ -n "$GUID" ]; then
    EFISIZE=2     # MB
    EFIPARTTYPE=ef02

    set $(ptgen -o "$OUTPUT" -h $head -s $sect -g \
        -t "${KERNELPARTTYPE}" -p "${KERNELSIZE}m${PARTOFFSET:+@$PARTOFFSET}" \
        -t "${ROOTFSPARTTYPE}" -p "${ROOTFSSIZE}m" \
        -t "${EFIPARTTYPE}" -p "${EFISIZE}m" \
        ${ALIGN:+-l $ALIGN} ${SIGNATURE:+-S 0x$SIGNATURE} ${GUID:+-G $GUID})

    KERNELOFFSET="$(($1 / 512))"
    KERNELSIZE="$2"
    ROOTFSOFFSET="$(($3 / 512))"
    ROOTFSSIZE="$(($4 / 512))"
    EFIOFFSET="$(($5 / 512))"
    EFISIZE_SECTORS="$(($6 / 512))"

    dd if=/dev/zero of="$OUTPUT.efipart" bs=1M count=$EFISIZE
    mkfs.fat -n EFI "$OUTPUT.efipart"
    dd if="$OUTPUT.efipart" of="$OUTPUT" bs=512 seek="$EFIOFFSET" conv=notrunc
    rm -f "$OUTPUT.efipart"
fi
EOF
            echo "[OK] gen_image_generic.sh 已注入 EF02 支持 ✅"
        else
            echo "[INFO] gen_image_generic.sh 已包含 EF02 逻辑，跳过"
        fi
    else
        echo "[WARN] gen_image_generic.sh not found: $GEN_IMAGE_GENERIC"
    fi
}

# ==============================
# 执行
# ==============================
fix_rust_compile_error
fix_config_generate
set_default_language_zh_cn
fix_gen_image_generic

echo "=============================="
echo "custom.sh done."
echo "=============================="
