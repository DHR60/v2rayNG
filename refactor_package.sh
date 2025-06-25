#!/bin/bash

# 定义旧包名和新包名
OLD_PACKAGE="com.v2ray.ang"
NEW_PACKAGE="com.clearpath.vng"

# 定义旧包和新包的路径
OLD_PACKAGE_PATH="V2rayNG/app/src/main/java/com/v2ray/ang"
NEW_PACKAGE_PATH="V2rayNG/app/src/main/java/com/clearpath/vng"
# 定义测试目录路径
OLD_TEST_PATH="V2rayNG/app/src/test/java/com/v2ray/ang"
NEW_TEST_PATH="V2rayNG/app/src/test/java/com/clearpath/vng"

# 添加删除空父目录的函数
remove_empty_parent_dirs() {
  local dir="$1"
  local base_dir="$2"  # 基础目录，不应该被删除
  
  # 获取父目录
  local parent_dir=$(dirname "$dir")
  
  # 如果已经到达基础目录或根目录，停止递归
  if [ "$parent_dir" = "$base_dir" ] || [ "$parent_dir" = "/" ] || [ "$parent_dir" = "." ]; then
    return
  fi
  
  # 如果父目录为空，删除它并继续递归
  if [ -d "$parent_dir" ] && [ -z "$(ls -A "$parent_dir" 2>/dev/null)" ]; then
    echo "删除空目录: $parent_dir"
    rmdir "$parent_dir"
    # 递归检查更上层的父目录
    remove_empty_parent_dirs "$parent_dir" "$base_dir"
  fi
}

echo "=============================="
echo "重构包名调试信息"
echo "当前工作目录: $(pwd)"
echo "旧包名: $OLD_PACKAGE"
echo "新包名: $NEW_PACKAGE"
echo "旧包路径: $OLD_PACKAGE_PATH"
echo "新包路径: $NEW_PACKAGE_PATH"
echo "旧测试路径: $OLD_TEST_PATH"
echo "新测试路径: $NEW_TEST_PATH"
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

# 3.1. 处理测试目录
echo "步骤3.1: 处理测试目录..."
if [ -d "$OLD_TEST_PATH" ]; then
  echo "发现测试目录，开始处理..."
  # 创建新的测试目录结构
  mkdir -p "$NEW_TEST_PATH"
  
  # 复制所有测试文件到新位置，同时替换文件内容
  for file in $(find "$OLD_TEST_PATH" -type f); do
    # 计算目标文件路径
    target_file="${file/$OLD_TEST_PATH/$NEW_TEST_PATH}"
    target_dir=$(dirname "$target_file")
    
    # 确保目标目录存在
    mkdir -p "$target_dir"
    
    # 复制文件到新位置，同时替换内容
    sed "s/$OLD_PACKAGE/$NEW_PACKAGE/g" "$file" > "$target_file"
    
    echo "处理测试文件: $file -> $target_file"
  done
  
  # 删除旧的测试目录
  rm -rf "$OLD_TEST_PATH"
  # 删除空的父目录
  remove_empty_parent_dirs "$OLD_TEST_PATH" "V2rayNG/app/src/test/java"
  echo "旧测试目录已删除"
else
  echo "测试目录不存在，跳过测试目录处理"
fi

# 4. 处理其他资源文件（layout, manifest等）
echo "步骤4: 更新资源文件..."
find V2rayNG/app/src/main -type f \( -name "*.xml" -o -name "*.properties" \) -exec sed -i "s/$OLD_PACKAGE/$NEW_PACKAGE/g" {} \;

# 5. 在删除旧包之前添加验证步骤
echo "步骤5: 验证文件迁移完整性..."
OLD_FILES_COUNT=$(find "$OLD_PACKAGE_PATH" -type f | wc -l)
NEW_FILES_COUNT=$(find "$NEW_PACKAGE_PATH" -type f | wc -l)
echo "旧包文件数: $OLD_FILES_COUNT"
echo "新包文件数: $NEW_FILES_COUNT"

# 6. 更新AndroidManifest.xml中的活动和服务引用
echo "步骤6: 更新AndroidManifest.xml活动和服务引用..."
sed -i "s/android:name=\"\.$OLD_PACKAGE/android:name=\"\.$NEW_PACKAGE/g" V2rayNG/app/src/main/AndroidManifest.xml
sed -i "s/android:name=\"$OLD_PACKAGE/android:name=\"$NEW_PACKAGE/g" V2rayNG/app/src/main/AndroidManifest.xml

# 7. 删除旧包
echo "步骤7: 删除旧包..."
rm -rf "$OLD_PACKAGE_PATH"
# 删除空的父目录
remove_empty_parent_dirs "$OLD_PACKAGE_PATH" "V2rayNG/app/src/main/java"

# 8. 全面检查V2rayNG目录下是否还有旧包名残留
echo "步骤8: 检查V2rayNG目录下旧包名残留..."
MISSING_FILES=0

# 检查是否还有包含旧包名的文件夹路径
OLD_PACKAGE_DIRS=$(find V2rayNG -type d \( -path "*com/v2ray/ang*" -o -path "*com.v2ray.ang*" \) 2>/dev/null | wc -l)
if [ $OLD_PACKAGE_DIRS -gt 0 ]; then
  echo "发现 $OLD_PACKAGE_DIRS 个包含旧包路径的目录:"
  find V2rayNG -type d \( -path "*com/v2ray/ang*" -o -path "*com.v2ray.ang*" \) 2>/dev/null
  MISSING_FILES=$((MISSING_FILES + OLD_PACKAGE_DIRS))
fi

# 检查是否还有包含旧包名的文件路径
OLD_PACKAGE_FILES=$(find V2rayNG -type f \( -path "*com/v2ray/ang*" -o -path "*com.v2ray.ang*" \) 2>/dev/null | wc -l)
if [ $OLD_PACKAGE_FILES -gt 0 ]; then
  echo "发现 $OLD_PACKAGE_FILES 个包含旧包路径的文件:"
  find V2rayNG -type f \( -path "*com/v2ray/ang*" -o -path "*com.v2ray.ang*" \) 2>/dev/null
  MISSING_FILES=$((MISSING_FILES + OLD_PACKAGE_FILES))
fi

# 检查文件内容中是否还包含旧包名引用（包括点号格式）
# 排除二进制文件和不相关的配置文件
OLD_PACKAGE_CONTENT=$(grep -r -E "(com\.v2ray\.ang|com/v2ray/ang)" V2rayNG \
  --include="*.xml" --include="*.gradle" --include="*.kts" --include="*.properties" \
  --include="*.json" --include="*.kt" --include="*.java" \
  --exclude="*.aar" --exclude="*.jar" --exclude="*.so" \
  --exclude-dir="libs" \
  2>/dev/null | \
  grep -v "v2ray_config.json" | \
  wc -l)

if [ $OLD_PACKAGE_CONTENT -gt 0 ]; then
  echo "发现 $OLD_PACKAGE_CONTENT 处文件内容包含旧包名引用:"
  grep -r -E "(com\.v2ray\.ang|com/v2ray/ang)" V2rayNG \
    --include="*.xml" --include="*.gradle" --include="*.kts" --include="*.properties" \
    --include="*.json" --include="*.kt" --include="*.java" \
    --exclude="*.aar" --exclude="*.jar" --exclude="*.so" \
    --exclude-dir="libs" \
    2>/dev/null | \
    grep -v "v2ray_config.json" | \
    head -10
  if [ $OLD_PACKAGE_CONTENT -gt 10 ]; then
    echo "... 还有 $((OLD_PACKAGE_CONTENT - 10)) 处引用未显示"
  fi
  MISSING_FILES=$((MISSING_FILES + OLD_PACKAGE_CONTENT))
fi

# 额外检查：搜索所有可能的旧包名变体（排除误报）
echo "进行额外的旧包名变体检查..."
OLD_PACKAGE_VARIANTS=$(find V2rayNG \( -name "*v2ray*" -o -name "*ang*" \) -type f -o -type d 2>/dev/null | \
  grep -E "(v2ray|com\.v2ray)" | \
  grep -v "\.aar$" | \
  grep -v "\.jar$" | \
  grep -v "\.so$" | \
  grep -v "v2ray_config.json" | \
  grep -v "/libs/" | \
  wc -l)

if [ $OLD_PACKAGE_VARIANTS -gt 0 ]; then
  echo "发现 $OLD_PACKAGE_VARIANTS 个可能的旧包名变体:"
  find V2rayNG \( -name "*v2ray*" -o -name "*ang*" \) -type f -o -type d 2>/dev/null | \
    grep -E "(v2ray|com\.v2ray)" | \
    grep -v "\.aar$" | \
    grep -v "\.jar$" | \
    grep -v "\.so$" | \
    grep -v "v2ray_config.json" | \
    grep -v "/libs/" | \
    head -5
  if [ $OLD_PACKAGE_VARIANTS -gt 5 ]; then
    echo "... 还有 $((OLD_PACKAGE_VARIANTS - 5)) 项未显示"
  fi
  MISSING_FILES=$((MISSING_FILES + OLD_PACKAGE_VARIANTS))
fi

# 根据检查结果决定是否继续
if [ $MISSING_FILES -gt 0 ]; then
  echo "警告: 发现 $MISSING_FILES 处旧包名残留！"
  
  # 在自动化环境中使用环境变量控制行为
  if [ "${FORCE_CONTINUE:-false}" = "true" ]; then
    echo "FORCE_CONTINUE=true，即使有残留也继续执行"
  else
    echo "发现旧包名残留，请手动检查清理情况"
    exit 1
  fi
else
  echo "✓ 未发现旧包名残留，清理完成"
fi

# 9. 附加步骤: 修复通配符或子包引用
echo "步骤9: 修复通配符或子包引用..."
find $NEW_PACKAGE_PATH -type f -name "*.kt" -exec sed -i "s/import $OLD_PACKAGE\.\*/import $NEW_PACKAGE\.\*/g" {} \;
find $NEW_PACKAGE_PATH -type f -name "*.java" -exec sed -i "s/import $OLD_PACKAGE\.\*/import $NEW_PACKAGE\.\*/g" {} \;
find $NEW_PACKAGE_PATH -type f -name "*.xml" -exec sed -i "s/$OLD_PACKAGE\.\*/$NEW_PACKAGE\.\*/g" {} \;

# 10. 修复别名导入语句
echo "步骤10: 修复别名导入语句..."
find $NEW_PACKAGE_PATH -type f -name "*.kt" -exec sed -i "s/import $OLD_PACKAGE\([^*]\{1,\}\) as \([A-Za-z0-9_]\{1,\}\)/import $NEW_PACKAGE\1 as \2/g" {} \;

# 11. 修复普通导入语句 (非通配符) - 包含测试目录
echo "步骤11: 修复普通导入语句..."
find $NEW_PACKAGE_PATH -type f -name "*.kt" -exec sed -i "s/import $OLD_PACKAGE\./import $NEW_PACKAGE./g" {} \;
find $NEW_PACKAGE_PATH -type f -name "*.java" -exec sed -i "s/import $OLD_PACKAGE\./import $NEW_PACKAGE./g" {} \;

# 处理测试目录中的导入语句
if [ -d "$NEW_TEST_PATH" ]; then
  find $NEW_TEST_PATH -type f -name "*.kt" -exec sed -i "s/import $OLD_PACKAGE\./import $NEW_PACKAGE./g" {} \;
  find $NEW_TEST_PATH -type f -name "*.java" -exec sed -i "s/import $OLD_PACKAGE\./import $NEW_PACKAGE./g" {} \;
fi

# 12. 检查是否有遗漏的导入语句 - 包含测试目录
echo "步骤12: 检查是否有遗漏的旧包名引用..."
MISSED_IMPORTS=$(grep -r "$OLD_PACKAGE" --include="*.kt" --include="*.java" $NEW_PACKAGE_PATH $NEW_TEST_PATH 2>/dev/null | wc -l)
if [ $MISSED_IMPORTS -gt 0 ]; then
  echo "警告: 发现 $MISSED_IMPORTS 处可能未替换的旧包名引用"
  grep -r "$OLD_PACKAGE" --include="*.kt" --include="*.java" $NEW_PACKAGE_PATH $NEW_TEST_PATH 2>/dev/null
fi

# 13. 添加/更新 ProGuard 规则以支持 libv2ray
echo "=============================="
echo "步骤13: 配置 ProGuard 规则以支持 libv2ray..."

PROGUARD_FILE="V2rayNG/app/proguard-rules.pro"

# 定义 libv2ray 相关的 ProGuard 规则
LIBV2RAY_RULES="
# libv2ray ProGuard 规则 - 解决 Release 构建问题
# 保留泛型签名信息 - 解决 ClassCastException 与 ParameterizedType 相关问题
-keepattributes Signature

# 保留 libv2ray 生成的 Java 桩代码
-keep class libv2ray.** { *; }

# 保留应用包下的所有类（基于新包名）
-keep class $NEW_PACKAGE.** { *; }

# 保留所有 native 方法（libv2ray 使用 JNI）
-keepclasseswithmembernames class * {
    native <methods>;
}

# 保留反射访问的类和方法
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# 保留可能通过反射访问的服务类
-keep class * extends android.app.Service { *; }
-keep class * implements android.os.Parcelable { *; }

# 保留 V2Ray 核心相关的类
-keep class * implements libv2ray.CoreCallbackHandler { *; }
-keep interface libv2ray.CoreCallbackHandler { *; }

# 防止混淆可能被反射调用的方法
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
"

# 检查 ProGuard 文件是否存在
if [ -f "$PROGUARD_FILE" ]; then
  # 检查是否已经包含 libv2ray 规则
  if grep -q "libv2ray ProGuard 规则" "$PROGUARD_FILE"; then
    echo "ProGuard 文件已包含 libv2ray 规则，跳过添加"
  else
    echo "在现有 ProGuard 文件中添加 libv2ray 规则..."
    echo "$LIBV2RAY_RULES" >> "$PROGUARD_FILE"
    echo "✓ libv2ray ProGuard 规则已添加"
  fi
else
  echo "创建新的 ProGuard 文件并添加 libv2ray 规则..."
  echo "$LIBV2RAY_RULES" > "$PROGUARD_FILE"
  echo "✓ 已创建 ProGuard 文件并添加 libv2ray 规则"
fi

# 自动化启用代码混淆 - 修改 build.gradle.kts
echo "自动启用 Release 构建的代码混淆..."
BUILD_GRADLE_FILE="V2rayNG/app/build.gradle.kts"

# 检查当前混淆状态
if grep -q "isMinifyEnabled = false" "$BUILD_GRADLE_FILE"; then
  # 启用代码混淆
  sed -i 's/isMinifyEnabled = false/isMinifyEnabled = true/g' "$BUILD_GRADLE_FILE"
  echo "✓ 已自动启用代码混淆: isMinifyEnabled = true"
elif grep -q "isMinifyEnabled = true" "$BUILD_GRADLE_FILE"; then
  echo "✓ 代码混淆已经启用"
else
  echo "警告: 未找到 isMinifyEnabled 配置，请手动检查"
fi

# 确保 build.gradle.kts 中配置了 proguardFiles
echo "检查 build.gradle.kts 中的 ProGuard 配置..."
if grep -q "proguardFiles" "$BUILD_GRADLE_FILE"; then
  echo "✓ build.gradle.kts 已配置 ProGuard"
  
  # 验证是否包含了 proguard-rules.pro
  if grep -q "proguard-rules.pro" "$BUILD_GRADLE_FILE"; then
    echo "✓ 已引用 proguard-rules.pro 文件"
  else
    echo "警告: 未发现 proguard-rules.pro 引用，可能需要手动添加"
  fi
else
  echo "警告: build.gradle.kts 中未发现 proguardFiles 配置，请手动检查 Release 构建配置"
fi

# 验证最终配置
echo "验证最终 ProGuard 配置..."
if [ -f "$PROGUARD_FILE" ] && grep -q "isMinifyEnabled = true" "$BUILD_GRADLE_FILE"; then
  echo "✓ ProGuard 配置完成并已启用"
else
  echo "⚠ ProGuard 配置可能不完整，请检查"
fi

echo "=============================="
echo "libv2ray ProGuard 配置完成"
echo "ProGuard 文件位置: $PROGUARD_FILE"
echo "代码混淆状态: $(grep -o 'isMinifyEnabled = [^,]*' "$BUILD_GRADLE_FILE" || echo "未找到配置")"
echo "=============================="

echo "重构完成，最终检查:"
echo "新包路径存在: $([ -d "$NEW_PACKAGE_PATH" ] && echo "是" || echo "否")"
echo "检测到的缺失文件数: $MISSING_FILES"
echo "=============================="

echo "Refactoring complete."

# 14. 清理项目
echo "步骤14: 清理并构建项目..."
cd V2rayNG
./gradlew clean
cd ..
