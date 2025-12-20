# Action-Openwrt

## 你好 👋

欢迎使用 OpenWrt 自动编译系统！

本项目使用 GitHub Actions 自动编译 OpenWrt 固件，支持 x64 平台。

## 特性说明

### 软件包签名配置
本固件已配置 `opkg` 禁用签名检查（`option check_signature 0`），解决安装第三方软件包时的签名验证问题。

**⚠️ 安全提示：** 禁用签名检查会降低系统安全性，仅在受信任的网络环境中安装软件包。如需更高安全性，建议配置受信任的签名密钥而非完全禁用验证。

![](https://github.com/xiaotan8/Openwrt-x64/workflows/Openwrt-AutoBuild/badge.svg)
![](https://img.shields.io/github/downloads/xiaotan8/Openwrt-x64/total)
![](https://img.shields.io/github/v/release/xiaotan8/Openwrt-x64)
