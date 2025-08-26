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

# 修复 Rust 编译错误（禁用下载 ci-llvm）
fix_rust_compile_error() {
    if [ -f "$RUST_MAKEFILE" ]; then
        echo "[INFO] Fixing Rust Makefile (disable download-ci-llvm)"
        sed -i 's/download-ci-llvm=true/download-ci-llvm=false/g' "$RUST_MAKEFILE"

        # 自动检测结果
        if grep -q "download-ci-llvm=false" "$RUST_MAKEFILE"; then
            echo "[OK] Rust Makefile 已成功修改 ✅"
        else
            echo "[FAIL] Rust Makefile 修改失败 ❌"
        fi
    else
        echo "[WARN] Rust Makefile not found: $RUST_MAKEFILE"
    fi
}

# 删除无用的 patch
remove_rust_patch() {
    PATCH_FILE="feeds/packages/lang/rust/patches/010-disable-ci-llvm.patch"
    echo "[Step 2] Removing unnecessary Rust patch"
    [ -f "$PATCH_FILE" ] && rm -f "$PATCH_FILE" && echo "[OK] Patch 删除成功 ✅" || echo "[INFO] Patch 不存在"
}

# 修改 trojan-plus 源码
fix_trojan_plus_source() {
    if [ -d "$TROJAN_SRC" ]; then
        echo "[Step 3] Applying trojan-plus source patch"

        patch -p1 -d "$TROJAN_SRC" <<'EOF'
--- a/src/core/service.cpp
+++ b/src/core/service.cpp
@@ -547,7 +547,7 @@ void Service::udp_async_read() {
             int ttl         = -1;
 
             targetdst = recv_tproxy_udp_msg((int)udp_socket.native_handle(), udp_recv_endpoint,
-              boost::asio::buffer_cast<char*>(udp_read_buf.prepare(config.get_udp_recv_buf())), read_length, ttl);
+              const_cast<char*>(static_cast<const char*>(udp_read_buf.prepare(config.get_udp_recv_buf()).data())), read_length, ttl);

       length = read_length < 0 ? 0 : read_length;
       udp_read_buf.commit(length);
EOF

        patch -p1 -d "$TROJAN_SRC" <<'EOF'
--- a/src/core/utils.cpp
+++ b/src/core/utils.cpp
@@ -59,8 +59,8 @@ size_t streambuf_append(
-    auto* dest      = boost::asio::buffer_cast<uint8_t*>(target.prepare(n));
-    const auto* src = boost::asio::buffer_cast<const uint8_t*>(append_buf.data()) + start;
+    auto* dest      = static_cast<uint8_t*>(target.prepare(n).data());
+    const auto* src = static_cast<const uint8_t*>(append_buf.data().data()) + start;
EOF

        patch -p1 -d "$TROJAN_SRC" <<'EOF'
--- a/src/session/session.cpp
+++ b/src/session/session.cpp
@@ -26,9 +26,11 @@
 size_t Session::s_total_session_count = 0;
+
 Session::Session(Service* _service, const Config& _config)
     : service(_service),
       udp_gc_timer(_service->get_io_context()),
+      udp_gc_timer_checker(0),
       pipeline_com(_config),
       is_udp_forward(false),
       config(_config) {}
EOF

        echo "[OK] Trojan-plus source patch applied ✅"
    else
        echo "[WARN] Trojan-plus source not found: $TROJAN_SRC"
    fi
}

# 修改默认网络配置
fix_config_generate() {
    if [ -f "$CONFIG_GENERATE" ]; then
        echo "[INFO] Found config_generate: $CONFIG_GENERATE"
        echo "[INFO] 修改默认 LAN 网络参数"

        # 修改默认 IP 地址
        sed -i 's/192\.168\.1\.1/10.10.10.10/g' "$CONFIG_GENERATE"

        # 修改默认网关
        sed -i 's/192\.168\.1\.1/10.10.10.1/g' "$CONFIG_GENERATE"

        # 添加默认 DNS
        sed -i '/ipaddr=10.10.10.10/a\        uci set network.lan.dns=10.10.10.10' "$CONFIG_GENERATE"

        # 自动检测结果
        echo "-------- 检查修改结果 --------"
        grep -E "10\.10\.10\.10|10\.10\.10\.1" "$CONFIG_GENERATE" || echo "[FAIL] 未找到修改结果 ❌"
        echo "-----------------------------"
    else
        echo "[WARN] config_generate not found: $CONFIG_GENERATE"
    fi
}

# 执行步骤
fix_rust_compile_error
remove_rust_patch
fix_trojan_plus_source
fix_config_generate

echo "=============================="
echo "custom.sh done."
echo "=============================="
