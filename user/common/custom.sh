#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo "Run custom.sh (must be executed from openwrt root)"
echo "========================================"

# ---- paths (relative to openwrt root) ----
RUST_MAKEFILE="feeds/packages/lang/rust/Makefile"
RUST_PATCH_FILE="feeds/packages/lang/rust/patches/010-disable-ci-llvm.patch"
TROJAN_PATCH_DIR="package/passwall-packages/trojan-plus/patches"
TROJAN_NEW_PATCH="$TROJAN_PATCH_DIR/001-fix-asio-buffer.patch"
TROJAN_OLD_PATCH="$TROJAN_PATCH_DIR/001-Fix-boost1.87-build.patch"
CONFIG_GENERATE="package/base-files/files/bin/config_generate"

# ---- Step 1: Fix Rust download-ci-llvm to avoid CI panic ----
echo "[Step 1] Fix Rust 'download-ci-llvm' in $RUST_MAKEFILE (if present)"
if [ -f "$RUST_MAKEFILE" ]; then
  # replace several common variants to "if-unchanged"
  sed -i.bak -e 's/download-ci-llvm[[:space:]]*=[[:space:]]*true/download-ci-llvm = "if-unchanged"/g' \
             -e 's/download-ci-llvm=true/download-ci-llvm = "if-unchanged"/g' \
             -e 's/download-ci-llvm=false/download-ci-llvm = "if-unchanged"/g' \
             "$RUST_MAKEFILE" || true
  if grep -q 'download-ci-llvm.*if-unchanged' "$RUST_MAKEFILE"; then
    echo "[OK] Rust Makefile updated to use if-unchanged."
  else
    echo "[WARN] Could not confirm change in $RUST_MAKEFILE (it may not contain download-ci-llvm)."
  fi
else
  echo "[INFO] $RUST_MAKEFILE not found, skipping Rust Makefile tweak."
fi

# remove old rust patch file if it exists (optional)
if [ -f "$RUST_PATCH_FILE" ]; then
  echo "[INFO] Removing existing rust patch file: $RUST_PATCH_FILE"
  rm -f "$RUST_PATCH_FILE"
fi

# ---- Step 2: Write trojan-plus patch (overwrite) ----
echo "[Step 2] Ensure trojan-plus patch directory exists: $TROJAN_PATCH_DIR"
mkdir -p "$TROJAN_PATCH_DIR"

# remove old conflicting patch if present
if [ -f "$TROJAN_OLD_PATCH" ]; then
  echo "[INFO] Removing old conflicting patch: $TROJAN_OLD_PATCH"
  rm -f "$TROJAN_OLD_PATCH"
fi

echo "[Step 2] Writing new trojan-plus patch to: $TROJAN_NEW_PATCH"
cat > "$TROJAN_NEW_PATCH" <<'PATCH'
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
PATCH

# append second hunk
cat >> "$TROJAN_NEW_PATCH" <<'PATCH'
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
PATCH

# append third hunk
cat >> "$TROJAN_NEW_PATCH" <<'PATCH'
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
PATCH

# ensure correct perms and newline at EOF
chmod 644 "$TROJAN_NEW_PATCH"
# show info
echo "[OK] wrote $TROJAN_NEW_PATCH ($(wc -c < "$TROJAN_NEW_PATCH") bytes)"
echo "[INFO] first 40 lines of patch:"
sed -n '1,40p' "$TROJAN_NEW_PATCH"

# ---- Step 3: Modify default network config (if exists) ----
echo "[Step 3] Modify default network config (if exists)"
if [ -f "$CONFIG_GENERATE" ]; then
  sed -i.bak -e 's/192\.168\.1\.1/10.10.10.10/g' "$CONFIG_GENERATE"
  # if you want ipaddr different from gateway adjust more precise rules; this simple replace replaces both occurrences
  sed -i -e 's/10\.10\.10\.10/10.10.10.10/g' "$CONFIG_GENERATE" || true
  sed -i -e 's/192\.168\.1\.1/10.10.10.1/g' "$CONFIG_GENERATE" || true
  sed -n '1,40p' "$CONFIG_GENERATE" | sed -n '1,20p'
  echo "[OK] network config modified (backup saved to ${CONFIG_GENERATE}.bak)"
else
  echo "[INFO] $CONFIG_GENERATE not found, skipping network modification"
fi

echo "========================================"
echo "custom.sh finished"
echo "========================================"
