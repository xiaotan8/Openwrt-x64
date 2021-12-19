#!/bin/bash

echo "Apply custom.sh"
rm -rf luci/themes/luci-theme-argon
git clone https://github.com/jerrykuku/luci-theme-argon.git                                       luci/themes/luci-theme-argon
