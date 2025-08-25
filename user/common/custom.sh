#!/bin/bash

echo "Apply custom.sh"
mkdir -p openwrt/feeds/packages/lang/rust/patches
cat > openwrt/feeds/packages/lang/rust/patches/010-disable-ci-llvm.patch <<'EOF'
--- a/src/bootstrap/config.toml.example
+++ b/src/bootstrap/config.toml.example
@@ -146,7 +146,7 @@
 # Whether to download prebuilt LLVM from CI. This is only supported on
 # 64-bit x86 platforms, and requires curl and tar to be installed.
 #
-# download-ci-llvm = true
+download-ci-llvm = "if-unchanged"
EOF
