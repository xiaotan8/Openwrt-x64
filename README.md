# Action-Openwrt

OpenWrt 自动编译构建项目，支持多版本自动化编译和发布。

![](https://github.com/xiaotan8/Openwrt-x64/workflows/Openwrt-AutoBuild/badge.svg)
![](https://img.shields.io/github/downloads/xiaotan8/Openwrt-x64/total)
![](https://img.shields.io/github/v/release/xiaotan8/Openwrt-x64)

---

## 📋 目录

- [项目简介](#项目简介)
- [项目特性](#项目特性)
- [支持版本](#支持版本)
- [项目结构](#项目结构)
- [快速开始](#快速开始)
- [配置说明](#配置说明)
- [构建流程](#构建流程)
- [时间线](#时间线)
- [常见问题](#常见问题)

---

## 🎯 项目简介

本项目是一个基于 GitHub Actions 的 OpenWrt 自动化编译系统，支持多个 OpenWrt 版本的自动构建、编译和发布。通过配置文件和自定义脚本，可以快速定制和编译符合需求的 OpenWrt 固件。

---

## ✨ 项目特性

- ✅ **自动化编译**：支持定时触发或手动触发编译
- ✅ **多版本支持**：同时编译 OpenWrt25.12 和 OpenWrtSNAPSHOT 版本
- ✅ **灵活配置**：通过 settings.ini 配置编译参数
- ✅ **自定义脚本**：支持自定义 custom.sh 和补丁文件
- ✅ **多种上传方式**：支持 Artifacts、Release、奶牛快传等
- ✅ **智能管理**：自动删除旧版本和工作流运行记录
- ✅ **微信通知**：编译完成后支持微信通知
- ✅ **SSH 远程连接**：支持 SSH 调试编译过程

---

## 📦 支持版本

| 版本 | 分支 | 说明 |
|------|------|------|
| OpenWrt25.12 | openwrt-25.12 | 稳定版本 |
| OpenWrtSNAPSHOT | master | 最新开发版本 |

---

## 📁 项目结构

```
Openwrt-x64/
├── .github/
│   └── workflows/
│       └── Openwrt-Build.yml          # GitHub Actions 工作流配置
├── user/
│   ├── common/                         # 公共配置（所有版本共用）
│   │   ├── custom.sh                   # 公共自定义脚本
│   │   ├── patches/                    # 公共补丁文件
│   │   └── files/                      # 公共文件覆盖
│   ├── OpenWrt25.12/                   # 稳定版本配置
│   │   ├── config.diff                 # 编译配置文件
│   │   ├── custom.sh                   # 版本特定自定义脚本
│   │   ├── settings.ini                # 版本配置参数
│   │   ├── patches/                    # 版本特定补丁
│   │   └── files/                      # 版本特定文件覆盖
│   └── OpenWrtSNAPSHOT/                # 开发版本配置
│       ├── config.diff
│       ├── custom.sh
│       ├── settings.ini
│       ├── patches/
│       └── files/
└── README.md                            # 本文件
```

---

## 🚀 快速开始

### 前提条件

- GitHub 账户并拥有本仓库
- 了解基本的 OpenWrt 编译知识
- （可选）配置 WeChat 通知需要 Server 酱 Token

### 基本步骤

1. **Fork 本仓库**到您的账户

2. **配置 Settings.ini**
   - 修改 `user/OpenWrt25.12/settings.ini`
   - 修改 `user/OpenWrtSNAPSHOT/settings.ini`

3. **触发编译**
   - 进入 GitHub Actions 标签页
   - 选择 "Openwrt-AutoBuild" 工作流
   - 点击 "Run workflow"

4. **获取固件**
   - 编译完成后，在 Releases 页面下载固件
   - 或从 Actions 的 Artifacts 中下载

---

## ⚙️ 配置说明

### settings.ini 配置参数

| 参数 | 说明 | 示例 |
|------|------|------|
| REPO_URL | OpenWrt 仓库地址 | `https://github.com/openwrt/openwrt.git` |
| REPO_BRANCH | OpenWrt 分支 | `openwrt-25.12` 或 `master` |
| UPLOAD_PACKAGES_DIR | 上传 Packages 目录 | `true` / `false` |
| UPLOAD_TARGETS_DIR | 上传 Targets 目录 | `true` / `false` |
| UPLOAD_FIRMWARE | 上传固件文件 | `true` / `false` |
| UPLOAD_TO_ARTIFACTS | 上传到 GitHub Artifacts | `true` / `false` |
| UPLOAD_TO_REALEASE | 发布到 Release | `true` / `false` |
| UPLOAD_TO_COWTRANSFER | 上传到奶牛快传 | `true` / `false` |
| WECHAT_NOTIFICATION | 微信通知 | `true` / `false` |
| DELETE_RELEASE | 自动删除旧 Release | `true` / `false` |
| DELETE_ARTIFACTS | 自动删除旧 Artifacts | `true` / `false` |

### 自定义脚本

#### custom.sh

在 feeds 安装后执行的自定义脚本，可用于：
- 安装额外的包
- 修改配置文件
- 应用自定义补丁

**使用位置：**
- `user/common/custom.sh` - 所有版本执行
- `user/OpenWrt25.12/custom.sh` - 仅 25.12 版本执行
- `user/OpenWrtSNAPSHOT/custom.sh` - 仅 SNAPSHOT 版本执行

#### 补丁文件

在 `patches/` 目录放置 `.patch` 文件：
- `user/common/patches/` - 公共补丁
- `user/[版本]/patches/` - 版本特定补丁

---

## 🔄 构建流程

### 工作流步骤

1. **环境初始化**
   - 检出代码
   - 设置时区为 Asia/Shanghai
   - 清理 Docker 和系统文件
   - 更新系统包和安装编译依赖

2. **代码准备**
   - 加载 settings.ini 配置
   - Clone OpenWrt 源码
   - 应用补丁文件

3. **Feeds 处理**
   - 更新 Feeds
   - 安装 Feeds
   - 执行自定义脚本

4. **编译阶段**
   - 加载 config.diff 配置
   - 执行 defconfig
   - 下载编译所需的包
   - 并行编译固件（使用 CPU 核心数 + 1）

5. **打包上传**
   - 打包 Packages 目录
   - 打包 Targets 目录
   - 汇总固件文件
   - 上传到配置的目标位置

6. **管理维护**
   - 删除旧版本（可配置保留数量）
   - 删除旧的工作流运行记录
   - 发送微信通知

### 触发方式

| 触发方式 | 说明 | 时间 |
|--------|------|------|
| 手动触发 | 在 GitHub Actions 页面手动运行 | 立即 |
| 定时触发 | 按照 Cron 表达式定时执行 | 每天 UTC 6:00（北京时间 14:00） |

---

## 📅 时间线

### 项目里程碑

| 时间 | 事件 | 状态 |
|------|------|------|
| 2024-01-01 | 项目初建 | ✅ 完成 |
| 2024-Q1 | 支持 OpenWrt25.12 编译 | ✅ 完成 |
| 2024-Q2 | 增加 SNAPSHOT 版本支持 | ✅ 完成 |
| 2024-Q3 | 实现 WeChat 通知功能 | ✅ 完成 |
| 2024-Q4 | 支持 SSH 远程调试 | ✅ 完成 |
| 2025-01 | 自动版本管理功能 | ✅ 完成 |

### 定时编译时间表

**配置说明：** `0 6 * * *`
- 分钟：0
- 小时：6（UTC）= 14:00（北京时间 UTC+8）
- 每天执行
- 执行时间：**每天下午 14:00（北京时间）**

### 最近版本发布时间

最新的构建和发布信息请查看 [Releases](https://github.com/xiaotan8/Openwrt-x64/releases) 页面。

---

## ❓ 常见问题

### Q: 如何修改编译配置？

A: 修改 `user/[版本]/config.diff` 文件，或在编译前通过 SSH 连接进行交互式配置。

### Q: 如何添加自定义包？

A: 编辑 `user/[版本]/custom.sh` 或 `user/common/custom.sh`，使用 `./scripts/feeds install` 安装。

### Q: 编译失败如何调试？

A: 启用 SSH 选项重新运行工作流，通过 SSH 连接进行交互式调试。

### Q: 如何启用 WeChat 通知？

A: 
1. 获取 [Server 酱](https://sct.ftqq.com) Token
2. 在 GitHub Secrets 中添加 `SCKEY`
3. 在 settings.ini 中设置 `WECHAT_NOTIFICATION="true"`

### Q: 支持 x86_64 以外的架构吗？

A: 可以，修改 settings.ini 中的 `REPO_BRANCH` 和 `config.diff`，选择其他架构的配置。

### Q: 如何保留更多的旧版本？

A: 修改工作流文件中的 `keep_latest` 参数值。

---

## 📝 许可证

MIT License

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进本项目！

---

## 📞 联系方式

- GitHub Issues：报告 Bug 或提交功能建议
- GitHub Discussions：讨论和问答
