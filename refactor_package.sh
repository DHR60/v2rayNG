#!/bin/bash

# 定义旧包名和新包名
OLD_PACKAGE="com.v2ray.ang"
NEW_PACKAGE="com.clearpath.app"

# 定义旧包和新包的路径
OLD_PACKAGE_PATH="V2rayNG/app/src/main/java/com/v2ray/ang"
NEW_PACKAGE_PATH="V2rayNG/app/src/main/java/com/clearpath/app"

echo "=============================="
echo "重构包名调试信息"
echo "当前工作目录: $(pwd)"
echo "旧包名: $OLD_PACKAGE"
echo "新包名: $NEW_PACKAGE"
echo "旧包路径: $OLD_PACKAGE_PATH"
echo "新包路径: $NEW_PACKAGE_PATH"
echo "=============================="

echo "Refactoring package from $OLD_PACKAGE to $NEW_PACKAGE..."

# 检查是否已替换，防止重复执行
if grep -q "applicationId = \"$NEW_PACKAGE\"" V2rayNG/app/build.gradle.kts; then
  echo "Package name already updated to $NEW_PACKAGE"
  exit 0
fi

# 完全重构方法 - 使用sed直接全局替换所有文件内容
echo "执行完全重构..."

# 1. 先全局替换build.gradle文件
echo "步骤1: 更新Gradle配置..."
sed -i "s/$OLD_PACKAGE/$NEW_PACKAGE/g" V2rayNG/app/build.gradle.kts
sed -i "s/$OLD_PACKAGE/$NEW_PACKAGE/g" V2rayNG/build.gradle.kts

# 2. 创建新的包目录结构
echo "步骤2: 创建目标包目录..."
mkdir -p "$NEW_PACKAGE_PATH"

# 3. 复制所有文件到新位置，同时替换文件内容
echo "步骤3: 复制并替换文件内容..."
for file in $(find "$OLD_PACKAGE_PATH" -type f); do
  # 计算目标文件路径
  target_file="${file/$OLD_PACKAGE_PATH/$NEW_PACKAGE_PATH}"
  target_dir=$(dirname "$target_file")
  
  # 确保目标目录存在
  mkdir -p "$target_dir"
  
  # 复制文件到新位置，同时替换内容
  sed "s/$OLD_PACKAGE/$NEW_PACKAGE/g" "$file" > "$target_file"
  
  echo "处理: $file -> $target_file"
done

# 4. 处理其他资源文件（layout, manifest等）
echo "步骤4: 更新资源文件..."
find V2rayNG/app/src/main -type f \( -name "*.xml" -o -name "*.properties" \) -exec sed -i "s/$OLD_PACKAGE/$NEW_PACKAGE/g" {} \;

# 7. 更新AndroidManifest.xml中的活动和服务引用
echo "步骤7: 更新AndroidManifest.xml活动和服务引用..."
sed -i "s/android:name=\"\.$OLD_PACKAGE/android:name=\"\.$NEW_PACKAGE/g" V2rayNG/app/src/main/AndroidManifest.xml
sed -i "s/android:name=\"$OLD_PACKAGE/android:name=\"$NEW_PACKAGE/g" V2rayNG/app/src/main/AndroidManifest.xml

# 8. 删除旧包（可选）
echo "步骤8: 删除旧包..."
rm -rf "$OLD_PACKAGE_PATH"

# 9. 清理项目
echo "步骤9: 清理并构建项目..."
cd V2rayNG
./gradlew clean

# 附加步骤: 修复通配符或子包引用...
echo "附加步骤: 修复通配符或子包引用..."
# 使用相对于当前目录（V2rayNG）的路径
find "app/src/main/java/com/clearpath/app" -type f -name "*.kt" -exec sed -i "s/import $OLD_PACKAGE\.\*/import $NEW_PACKAGE\.\*/g" {} \;

echo "=============================="
echo "重构完成，最终检查:"
echo "新包路径存在: $([ -d "app/src/main/java/com/clearpath/app" ] && echo "是" || echo "否")"
echo "旧包路径仍存在: $([ -d "app/src/main/java/com/v2ray/ang" ] && echo "是 - 可能有问题" || echo "否 - 正常")"
echo "=============================="

echo "Refactoring complete."
