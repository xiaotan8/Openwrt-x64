#!/bin/bash

echo "Apply custom.sh"
rm -rf feeds/luci/themes/luci-theme-argon
git clone https://github.com/jerrykuku/luci-theme-argon.git                                       feeds/luci/themes/luci-theme-argon
