#! /bin/bash

set -e
root_dir=$(cd `dirname $0`/.. && pwd -P)
NW_PACKAGE_DIR="$root_dir/package.nw"

if [ -z "$NW_PACKAGE_DIR" ]; then
    echo -e "\e[1;31m\$NW_PACKAGE_DIR is empty\e[0m" >&2
    exit 1
fi

cd "$NW_PACKAGE_DIR"

sed 's#AppData/Local/\${global.userDirName}/User Data/\${global.productHash}/Default#.config/\${global.userDirName}/Default#g' js/common/cli/index.js > /tmp/sed_file; cat /tmp/sed_file > js/common/cli/index.js
sed 's#USERPROFILE#HOME#g' js/common/cli/index.js > /tmp/sed_file; cat /tmp/sed_file > js/common/cli/index.js
sed 's#`./\${global.appname}.exe`#`./bin/\${global.appname}`#g' js/common/cli/index.js > /tmp/sed_file; cat /tmp/sed_file > js/common/cli/index.js
sed 's#,""));const T#,""));_.$0="wechat-devtools-cli";const T#' js/common/cli/index.js > /tmp/sed_file; cat /tmp/sed_file > js/common/cli/index.js
