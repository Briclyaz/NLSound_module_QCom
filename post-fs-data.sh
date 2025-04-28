target_module="NLSound"
modules=/data/adb/modules

# post-fs-data 5s执行超时，不要太贪心哦
map_files() {
  local module=$1
  local dir=$2
  for file in $(ls $module/$dir)
  do
    local abs_path="$module/$dir/$file"
    if [[ -f "$abs_path" ]]; then
      if [[ -f "/$dir/$file" ]]; then
        echo "   > $module  $dir/$file"
        mount --bind "$abs_path" "/$dir/$file"
      else
        echo "   ! $module  $dir/$file"
      fi
      # mount --bind 
    elif [[ -d "$abs_path" ]]; then
      echo "   + $module  $dir/$file"
      map_files "$module" "$dir/$file"
    else
      # 正常应该不会有非文件又非目录的东西再这里
      # 遇到这个错误，应该是module和dir被当作全局变量了
      echo "???" "$abs_path"
    fi
  done
}

if [[ "$KSU" == "true" ]] || [[ $(which ksud) != "" ]]; then
  for module in $modules/$target_module
  do
    # 遍历需要处理的特殊目录
    for dir in 'sys' 'my_product' 'odm'
    do
      if [[ -d $module/$dir ]]; then
        echo ">> $module/$dir"
        map_files "$module" "$dir"
      fi
    done
  done
else
  for module in $modules/$target_module
  do
    # 遍历需要处理的特殊目录
    for dir in 'sys' 'my_product' 'odm'
    do
      if [[ -d $module/$dir ]]; then
        echo ">> $module/$dir"
        map_files "$module" "$dir"
      fi
    done
  done
fi
