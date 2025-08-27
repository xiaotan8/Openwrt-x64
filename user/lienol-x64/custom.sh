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
RUST_PATCH="feeds/packages/lang/rust/patches/010-disable-ci-llvm.patch"
CONFIG_GENERATE="package/base-files/files/bin/config_generate"
TROJAN_PATCH_DIR="package/passwall-packages/trojan-plus/patches"
TROJAN_PATCH_FILE="$TROJAN_PATCH_DIR/001-fix-asio-buffer.patch"

# -----------------------------
# Step 1: 修复 Rust 编译错误（禁用下载 ci-llvm）
# -----------------------------
fix_rust_compile_error() {
    echo "[Step 1] Fix Rust Makefile"
    if [ -f "$RUST_MAKEFILE" ]; then
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

# -----------------------------
# Step 2: 删除 Rust 补丁 010-disable-ci-llvm.patch
# -----------------------------
remove_rust_patch() {
    echo "[Step 2] Removing unnecessary Rust patch"
    if [ -f "$RUST_PATCH" ]; then
        rm -f "$RUST_PATCH"
        echo "[OK] Removed $RUST_PATCH"
    else
        echo "[INFO] Patch 不存在"
    fi
}

# -----------------------------
# Step 2b: 删除旧 trojan-plus 补丁 001-Fix-boost1.87-build.patch
# -----------------------------
remove_old_trojan_patch() {
    echo "[Step 2b] Remove old trojan-plus patch if exists"
    OLD_TROJAN_PATCH="$TROJAN_PATCH_DIR/001-Fix-boost1.87-build.patch"
    if [ -f "$OLD_TROJAN_PATCH" ]; then
        rm -f "$OLD_TROJAN_PATCH"
        echo "[OK] Removed $OLD_TROJAN_PATCH"
    else
        echo "[INFO] No old trojan-plus patch to remove ($OLD_TROJAN_PATCH)"
    fi
}

# -----------------------------
# Step 3: 写入 trojan-plus asio 补丁
# -----------------------------
write_trojan_patch() {
    echo "[Step 3] Apply trojan-plus patch"
    if [ -d "$TROJAN_PATCH_DIR" ]; then
        cat > "$TROJAN_PATCH_FILE" << 'EOF'
diff --git a/src/core/service.cpp b/src/core/service.cpp
index 8ab2623..ca57dda 100644
--- a/src/core/service.cpp
+++ b/src/core/service.cpp
@@ -547,7 +547,7 @@ void Service::udp_async_read() {
             int ttl         = -1;
 
             targetdst = recv_tproxy_udp_msg((int)udp_socket.native_handle(), udp_recv_endpoint,
-              boost::asio::buffer_cast<char*>(udp_read_buf.prepare(config.get_udp_recv_buf())), read_length, ttl);
+              const_cast<char*>(static_cast<const char*>(udp_read_buf.prepare(config.get_udp_recv_buf()).data())), read_length, ttl);

       length = read_length < 0 ? 0 : read_length;
       udp_read_buf.commit(length);

       length = read_length < 0 ? 0 : read_length;
       udp_read_buf.commit(length);

 
             length = read_length < 0 ? 0 : read_length;
             udp_read_buf.commit(length);


diff --git a/src/core/utils.cpp b/src/core/utils.cpp
index 7977fba..f2beb8a 100644
--- a/src/core/utils.cpp
+++ b/src/core/utils.cpp
@@ -59,8 +59,8 @@ size_t streambuf_append(
         return 0;
     }
 
-    auto* dest      = boost::asio::buffer_cast<uint8_t*>(target.prepare(n));
-    const auto* src = boost::asio::buffer_cast<const uint8_t*>(append_buf.data()) + start;
+    auto* dest      = static_cast<uint8_t*>(target.prepare(n).data());
+    const auto* src = static_cast<const uint8_t*>(append_buf.data().data()) + start;
     memcpy(dest, src, n);
     target.commit(n);
     return n;
@@ -102,7 +102,7 @@ size_t streambuf_append(boost::asio::streambuf& target, const uint8_t* append_da
 size_t streambuf_append(boost::asio::streambuf& target, char append_char) {
     _guard;
     const size_t char_length = sizeof(char);
-    auto cp = gsl::span<char>(boost::asio::buffer_cast<char*>(target.prepare(char_length)), char_length);
+    auto cp = gsl::span<char>(static_cast<char*>(target.prepare(char_length).data()), char_length);
     cp[0]   = append_char;
     target.commit(char_length);
     return char_length;
@@ -137,7 +137,7 @@ size_t streambuf_append(boost::asio::streambuf& target, const std::string& appen
 
 std::string_view streambuf_to_string_view(const boost::asio::streambuf& target) {
     _guard;
-    return std::string_view(boost::asio::buffer_cast<const char*>(target.data()), target.size());
+    return std::string_view(static_cast<const char*>(target.data().data()), target.size());
     _unguard;
 }
 

diff --git a/src/session/session.cpp b/src/session/session.cpp
index 4367ca5..23524b5 100644
--- a/src/session/session.cpp
+++ b/src/session/session.cpp
@@ -26,9 +26,11 @@
 using namespace std;
 
 size_t Session::s_total_session_count = 0;
+
 Session::Session(Service* _service, const Config& _config)
     : service(_service),
       udp_gc_timer(_service->get_io_context()),
+      udp_gc_timer_checker(0),
       pipeline_com(_config),
       is_udp_forward(false),
       config(_config),
@@ -40,7 +42,7 @@ Session::~Session() {
     s_total_session_count--;
     _log_with_date_time_ALL((is_udp_forward_session() ? "[udp] ~" : "[tcp] ~") + string(session_name) +
                             " called, current all sessions:  " + to_string(s_total_session_count));
-};
+}
 
 int Session::get_udp_timer_timeout_val() const { return get_config().get_udp_timeout(); }
 
@@ -67,22 +69,16 @@ void Session::udp_timer_async_wait(int timeout /*=-1*/) {
         udp_gc_timer_checker = time(nullptr);
     }
 
-    boost::system::error_code ec;
-    udp_gc_timer.cancel(ec);
-    if (ec) {
-        output_debug_info_ec(ec);
-        destroy();
-        return;
-    }
+    udp_gc_timer.cancel();
 
     udp_gc_timer.expires_after(chrono::seconds(timeout));
     auto self = shared_from_this();
-    udp_gc_timer.async_wait([this, self, timeout](const boost::system::error_code error) {
+    udp_gc_timer.async_wait([this, self, timeout](const boost::system::error_code& error) {
         _guard;
         if (!error) {
             auto curr = time(nullptr);
             if (curr - udp_gc_timer_checker < timeout) {
-                auto diff            = int(timeout - (curr - udp_gc_timer_checker));
+                auto diff = timeout - (curr - udp_gc_timer_checker);
                 udp_gc_timer_checker = 0;
                 udp_timer_async_wait(diff);
                 return;
@@ -90,6 +86,8 @@ void Session::udp_timer_async_wait(int timeout /*=-1*/) {
 
             _log_with_date_time("session_id: " + to_string(get_session_id()) + " UDP session timeout");
             destroy();
+        } else if (error != boost::asio::error::operation_aborted) {
+            output_debug_info_ec(error);
         }
         _unguard;
     });
@@ -99,14 +97,13 @@ void Session::udp_timer_async_wait(int timeout /*=-1*/) {
 
 void Session::udp_timer_cancel() {
     _guard;
+
     if (udp_gc_timer_checker == 0) {
         return;
     }
 
-    boost::system::error_code ec;
-    udp_gc_timer.cancel(ec);
-    if (ec) {
-        output_debug_info_ec(ec);
-    }
+    udp_gc_timer.cancel();
+
+    udp_gc_timer_checker = 0;
     _unguard;
 }
EOF
        echo "[OK] Trojan-plus patch applied: $TROJAN_PATCH_FILE"
    else
        echo "[WARN] Trojan-plus source not found: $TROJAN_PATCH_DIR"
    fi
}

# -----------------------------
# Step 4: 修改默认网络配置
# -----------------------------
fix_config_generate() {
    echo "[Step 4] Fix config_generate"
    if [ -f "$CONFIG_GENERATE" ]; then
        echo "[INFO] Found config_generate: $CONFIG_GENERATE"
        echo "[INFO] 修改默认 LAN 网络参数"

        # 修改默认 IP 地址
        sed -i 's/192\.168\.1\.1/10.10.10.10/g' "$CONFIG_GENERATE"

        # 修改默认网关
        sed -i 's/192\.168\.1\.1/10.10.10.1/g' "$CONFIG_GENERATE"

        # 添加默认 DNS
        sed -i '/ipaddr=10.10.10.10/a\        uci set network.lan.dns=10.10.10.10' "$CONFIG_GENERATE"

        echo "-------- 检查修改结果 --------"
        grep -E "10\.10\.10\.10|10\.10\.10\.1" "$CONFIG_GENERATE" || echo "[FAIL] 未找到修改结果 ❌"
        echo "-----------------------------"
    else
        echo "[WARN] config_generate not found: $CONFIG_GENERATE"
    fi
}

# =============================
# 执行顺序
# =============================
fix_rust_compile_error
remove_rust_patch
remove_old_trojan_patch
write_trojan_patch
fix_config_generate

echo "=============================="
echo "custom.sh done."
echo "=============================="
