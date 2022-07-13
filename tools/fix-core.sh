#!/bin/bash
root_dir=$(cd `dirname $0`/.. && pwd -P)

package_dir="$root_dir/package.nw"
tmp_dir="$root_dir/tmp/core"
mkdir -p $tmp_dir
unpack_script="$root_dir/tools/wxvpkg_unpack.js"
pack_script="$root_dir/tools/wxvpkg_pack.js"
 
echo "Fix Core"
# unpack 文件 到 路径
node "$unpack_script" "$package_dir/core.wxvpkg" "$tmp_dir/core.wxvpkg"

chmod -R 755 $tmp_dir

#    ____  _____ ____  _        _    ____ _____    ____ ___  ____  _____ 
#   |  _ \| ____|  _ \| |      / \  / ___| ____|  / ___/ _ \|  _ \| ____|
#   | |_) |  _| | |_) | |     / _ \| |   |  _|   | |  | | | | |_) |  _|  
#   |  _ <| |___|  __/| |___ / ___ \ |___| |___  | |__| |_| |  _ <| |___ 
#   |_| \_\_____|_|   |_____/_/   \_\____|_____|  \____\___/|_| \_\_____|
#                                                                        

# find
open_find_result=$( grep -lr "this.props.onWindowOpenFail());if" "$tmp_dir/core.wxvpkg" )
echo "云开发控制台启动点: $open_find_result"
if [[ ! -z $open_find_result ]];then
  # replace
  new_cb_handle="this.props.onWindowOpenFail());Object.keys(window).forEach(key=>{if(!e.window[key]){try{e.window[key]=window[key];}catch(e){console.error(e);}}});"
  sed "s/this.props.onWindowOpenFail());/$new_cb_handle/g" $open_find_result > /tmp/sed_file; cat /tmp/sed_file > $open_find_result
fi

token_find_result=$( grep -lr "constructor(){this._sessionToken=\"\",this._tokenMap={}}" "$tmp_dir/core.wxvpkg" )
echo "WebSocket token存储对象位置: $token_find_result"
if [[ ! -z $token_find_result ]];then
  new_constructor="constructor(){if(window.tokenData){/*有就直接用*/this._sessionToken=window.tokenData._sessionToken;this._tokenMap=window.tokenData._tokenMap;}else{/*没有就新建*/this._sessionToken=\"\",this._tokenMap={};window.tokenData=this;/*新建完要给中间人*/}}"
  sed "s#constructor(){this._sessionToken=\"\",this._tokenMap={}}#$new_constructor#g" "$token_find_result" > /tmp/sed_file; cat /tmp/sed_file > $token_find_result
fi

# open -a Terminal "`pwd`" --> gnome-terminal
find_result=$( grep -lr 'open -a Terminal "`pwd`"' "$tmp_dir/core.wxvpkg" )
echo "Terminal启动位置: $find_result"
if [[ ! -z $find_result ]];then
  new_str="gnome-terminal"
  sed "s#open -a Terminal \"\`pwd\`\"#$new_str#g" "$find_result" > /tmp/sed_file; cat /tmp/sed_file > $find_result
fi

# wcc、wcsc处理，设置WINE=fasle环境变量生效
if [[ "$WINE" != 'true' ]];then
  # "wcc.exe":!0,"wcsc.exe":!0
  find_result=$( grep -lr '{wcc:!0,wcsc:!0}' "$tmp_dir/core.wxvpkg" )
  echo "wcc: $find_result"
  if [[ ! -z $find_result ]];then
    new_str='{"wcc.bin":!0,"wcsc.bin":!0,wcc:!0,wcsc:!0}'
    sed "s#{wcc:!0,wcsc:!0}#$new_str#g" "$find_result" > /tmp/sed_file; cat /tmp/sed_file > $find_result
    new_str='"linux"===process.platform'
    sed "s#\"darwin\"===process.platform#$new_str#g" "$find_result" > /tmp/sed_file; cat /tmp/sed_file > $find_result
    
    return_exp_wcc=$(cat $find_result | grep -P 'return [a-z]+\("wcc"\)' -o)  # return ?("wcc")
    return_exp_wcc_replace="${return_exp_wcc//wcc/wcc.bin}" # return ?("wcc.bin")
    return_exp_wcc_replace="${return_exp_wcc//return /${return_exp_wcc_replace},}" # return ?("wcc.bin")

    return_exp_wcsc=$(cat $find_result | grep -P 'return [a-z]+\("wcsc"\)' -o)  # return ?("wcsc")
    return_exp_wcsc_replace="${return_exp_wcc_replace//wcc/wcsc}"

    sed "s#$return_exp_wcc#$return_exp_wcc_replace#g" "$find_result" > /tmp/sed_file; cat /tmp/sed_file > $find_result
    sed "s#$return_exp_wcsc#$return_exp_wcsc_replace#g" "$find_result" > /tmp/sed_file; cat /tmp/sed_file > $find_result
  fi
  # 处理报错时控制台显示的环境
  find_result=$( grep -lr '(env:' "$tmp_dir/core.wxvpkg" )
  echo "env: $find_result"
  if [[ ! -z $find_result ]];then
    for file in $find_result; do
      sed 's#"Windows"#"Linux"#g' "$file" > /tmp/sed_file; cat /tmp/sed_file > $file
    done
  fi

  current=`date "+%Y-%m-%d %H:%M:%S"`
  timeStamp=`date -d "$current" +%s`
  echo $timeStamp > "${package_dir}/.build_time"
fi

# fix theme
find_result=$( grep -lr "OSThemeController=" "$tmp_dir/core.wxvpkg" )
echo "theme: $find_result"
if [[ -n $find_result ]];then
  # require of child_process
  sed 's/"use strict";O/"use strict";const {execSync,spawn}=require("child_process");O/' $find_result > /tmp/sed_file; cat /tmp/sed_file > $find_result
  # replace listener to monitor
  sed 's/this.registerListeners()/this.monitorTheme()/' $find_result > /tmp/sed_file; cat /tmp/sed_file > $find_result
  # replace check func
  sed 's/mediaQuery.matches/isDark/' $find_result > /tmp/sed_file; cat /tmp/sed_file > $find_result
  # add functions
  sed 's#}getDefaultTheme#}get isDark(){try{const{DESKTOP_SESSION}=process.env;console.log(DESKTOP_SESSION);let theme="";switch(DESKTOP_SESSION){case"deepin":theme=execSync(`gsettings get com.deepin.dde.appearance gtk-theme`);break;case"gnome":case"gnome-classic":theme=execSync(`gsettings get org.gnome.desktop.interface ${this.gnomeScheme}`);break;default:break}return theme.includes("dark");}catch(err){console.error("尝试获取主题信息失败，使用默认暗色",err);return true;}}get gnomeScheme(){try{const gnomeVersion=execSync(`gnome-shell --version`).toString().replace(/[\\r\\n]/g,"").split(" ");const gnomeVersionNum=gnomeVersion.length==3?Number(gnomeVersion[2]):0;return gnomeVersionNum>=42?"color-scheme":"gtk-theme";}catch(err){console.error("检查gnome版本失败, 使用gtk-theme", err);return "gtk-theme";}}monitorTheme(){try{let monitor=null;const{DESKTOP_SESSION}=process.env;switch(DESKTOP_SESSION){case"deepin":monitor=spawn("gsettings",["monitor","com.deepin.dde.appearance","gtk-theme",]);break;case"gnome":case"gnome-classic":monitor=spawn("gsettings",["monitor","org.gnome.desktop.interface",this.gnomeScheme,]);break;default:console.warn(`NOT SUPPORTED!!!DESKTOP_SESSION:${DESKTOP_SESSION}`);break}monitor\&\&monitor.on("error",(err)=>{console.error("monitorTheme",err)});monitor\&\&monitor.stdout.on("data",e.debounce((chunk)=>{const data=chunk.toString();const t=data.toLowerCase().includes("dark");(this._theme=t?i.Dark:i.Light),this._onDidThemeChange.fire(this._theme)},400));process.on("SIGTERM",(signal)=>{monitor.kill(signal);});}catch(err){console.error("尝试监听主题失败！", err);}}getDefaultTheme#' $find_result > /tmp/sed_file; cat /tmp/sed_file > $find_result
fi

# fix update check
find_result=$( grep -lr "whatsnew.html" "$tmp_dir/core.wxvpkg" )
sed 's#t=>{W("new_version_hint#t=>{t.window.global.shareData=global.shareData;t.window.global.windowMap=global.windowMap;W("new_version_hint#' $find_result > /tmp/sed_file; cat /tmp/sed_file > $find_result

# pack 路径 到 文件
echo "pack"
node "$pack_script" "$tmp_dir/core.wxvpkg" "$package_dir/core.wxvpkg"
rm -rf "$tmp_dir/core.wxvpkg"
