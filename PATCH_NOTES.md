# PR #21288 补丁应用说明

## 问题描述

编译OpenWrt时出现以下错误：
```
ERROR: unable to select packages:
  ca-bundle-20250419-r1:
    conflicts: ca-certificates-20250419-r1[ca-certs=20250419-r1]
```

这是因为 `ca-bundle` 和 `ca-certificates` 两个包都试图提供相同的 `ca-certs` 组件，导致包管理器无法选择。

## 官方解决方案

OpenWrt官方在PR #21288中引入了**虚拟provides机制（virtual provides）**来解决此类冲突。

PR链接：https://github.com/openwrt/openwrt/pull/21288

### 核心改动：

1. **build: refactor provides logic** - 重构provides逻辑
2. **build: add support for virtual provides** - 添加虚拟provides支持  
3. **ca-certificates: provide a virtual ca-certs** - ca-certificates提供虚拟ca-certs
4. **build: provide virtual self in kmods** - 为kmod提供虚拟self
5. **kernel/r8169, ath10k, rtl8812au-ct** - 为各驱动提供虚拟kmod

## Action-Openwrt中的应用方式

本项目自动在 `custom.sh` 脚本中集成了PR #21288的补丁应用机制。

### 工作流程：

1. **GitHub Actions运行时**：
   - 克隆OpenWrt源码
   - 调用 `apply_pr21288_patch()` 函数
   - 该函数会从官方OpenWrt仓库获取PR #21288的提交
   - 使用 `git cherry-pick` 自动应用所有7个commit

2. **修改的文件**：
   ```
   user/OpenWrt25.12/custom.sh
   user/OpenWrtSNAPSHOT/custom.sh
   ```

### 补丁应用的关键部分：

```bash
apply_pr21288_patch() {
    echo "[INFO] Applying PR #21288 patch to fix ca-bundle/ca-certificates conflict"
    
    git remote add upstream https://github.com/openwrt/openwrt.git
    git fetch upstream pull/21288/head:pr-21288
    
    # 应用7个关键commit
    git cherry-pick da44bd045f2e2e04d9f540f4824118b25295cd20
    git cherry-pick 21be7558eb33209390a2c98f7a74b61b3a450cab
    git cherry-pick bfafeb93a4faefb76d31c97887e6efe609b45065
    git cherry-pick 0b17000c230f569b28597a69c3dd46d4f8caaef3
    git cherry-pick b0943f91ab48c67bc2530078ed558daf991d9849
    git cherry-pick a8917e9de91b037c978c679471359ff57eff5ca1
    git cherry-pick a221d075890d127ddbf49d11f67227bdaca7349b
}
```

## 使用方式

### 自动应用（推荐）

1. GitHub Actions自动编译时，会在源码clone后自动执行 `apply_pr21288_patch()`
2. 补丁应用成功将显示：
   ```
   [OK] PR #21288 commits applied ✅
   ```

### 本地测试应用

如果需要在本地测试：

```bash
cd openwrt
git remote add upstream https://github.com/openwrt/openwrt.git
git fetch upstream pull/21288/head:pr-21288
git cherry-pick da44bd045f2e2e04d9f540f4824118b25295cd20^..a221d075890d127ddbf49d11f67227bdaca7349b
```

## 预期效果

应用补丁后：
- ✅ `ca-bundle` 和 `ca-certificates` 可同时安装
- ✅ 其他包冲突（如iptables、wget等）也会得到修复
- ✅ kmod驱动的虚拟provides正确处理
- ✅ 编译不再出现provider冲突错误

## 相关链接

- PR #21288: https://github.com/openwrt/openwrt/pull/21288
- Issue #21257: https://github.com/openwrt/openwrt/issues/21257
- Packages PR #28180: https://github.com/openwrt/packages/issues/28180

## 备注

- 如果源码已包含此补丁（新版本），cherry-pick会显示警告但不影响编译
- 补丁应用失败时会打印 `[WARN]` 信息，编译继续进行
- 建议保持GitHub Actions更新以获得最新的补丁应用机制
