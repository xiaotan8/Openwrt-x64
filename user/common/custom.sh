#!/bin/bash

echo "Apply custom.sh"

# 1. 创建 Rust patch
mkdir -p openwrt/feeds/packages/lang/rust/patches
cat > openwrt/feeds/packages/lang/rust/patches/010-disable-ci-llvm.patch <<'EOF'
--- a/src/bootstrap/config.toml.example
+++ b/src/bootstrap/config.toml.example
@@ -146,7 +146,7 @@
-# download-ci-llvm = true
+download-ci-llvm = "if-unchanged"
EOF

# 2. 验证 patch 是否生成成功
echo "验证 Rust patch 是否生成成功:"
grep -R "download-ci-llvm" openwrt/feeds/packages/lang/rust

# 3. 修改 OpenWrt 默认网络
CONFIG_FILE="package/base-files/files/bin/config_generate"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE 不存在！"
    exit 1
fi

echo "修改默认 IP、网关和 DNS..."
sed -i 's/192\.168\.1\.1/10.10.10.10/g' "$CONFIG_FILE"
sed -i 's/192\.168\.1\.1/10.10.10.1/g' "$CONFIG_FILE"
sed -i '/ipaddr=10.10.10.10/a\        uci set network.lan.dns=10.10.10.10' "$CONFIG_FILE"

echo "修改完成."
