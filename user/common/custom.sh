#!/bin/bash

echo "Apply custom.sh"
rm -rf package/luci-theme-argon
git clone https://github.com/jerrykuku/luci-theme-argon.git                                       package/luci-theme-argon
