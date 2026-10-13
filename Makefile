# SaveEye macOS 应用构建和安装 Makefile

# 项目配置
PROJECT_NAME = SaveEye
SCHEME = SaveEye
CONFIGURATION = Release
BUILD_DIR = build
DERIVED_DATA_PATH = $(BUILD_DIR)/DerivedData
VERSION = $(shell git describe --tags --abbrev=0 2>/dev/null || echo "1.0.0")

# 应用路径
APP_NAME = $(PROJECT_NAME)
BUILT_APP_PATH = $(BUILD_DIR)/$(CONFIGURATION)/$(APP_NAME).app
INSTALL_PATH = /Applications/$(APP_NAME)
DIST_ZIP = $(BUILD_DIR)/$(CONFIGURATION)/$(PROJECT_NAME)-unsigned.zip
DMG_DIR = $(BUILD_DIR)/dmg
DMG_PATH = $(BUILD_DIR)/$(CONFIGURATION)/$(PROJECT_NAME)-$(VERSION)

# 目标架构（可通过 ARCH=x86_64 或 ARCH=arm64 覆盖，默认为本机架构）
ARCH ?= $(shell uname -m)
ifeq ($(ARCH),x86_64)
ARCH_SUFFIX = x86_64
else
ARCH_SUFFIX = arm64
endif

# GitHub 仓库信息
GITHUB_USER = samzong
GITHUB_REPO = SaveEye
HOMEBREW_TAP_REPO = homebrew-tap

# 版本信息
GIT_COMMIT = $(shell git rev-parse --short HEAD)
VERSION ?= $(if $(CI_BUILD),$(shell git describe --tags --always),Dev-$(shell git rev-parse --short HEAD))
CLEAN_VERSION = $(shell echo $(VERSION) | sed 's/^v//')

# Homebrew 相关变量
HOMEBREW_TAP_REPO = homebrew-tap
CASK_FILE = Casks/saveeye.rb
BRANCH_NAME = update-saveeye-$(CLEAN_VERSION)

# 构建应用
build:
	@echo "🔨 构建 $(PROJECT_NAME) 应用 (架构: $(ARCH_SUFFIX))..."
	@mkdir -p $(BUILD_DIR)
	xcodebuild \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA_PATH)-$(ARCH_SUFFIX) \
		-destination 'platform=macOS,arch=$(ARCH_SUFFIX)' \
		ARCHS=$(ARCH_SUFFIX) \
		ONLY_ACTIVE_ARCH=NO \
		build \
		SYMROOT=$(BUILD_DIR)
	@echo "🧹 清理扩展属性..."
	@xattr -cr "$(BUILT_APP_PATH)"
	@echo "📦 打包分发版本..."
	@cd "$(BUILD_DIR)/$(CONFIGURATION)" && zip -r "$(PROJECT_NAME)-unsigned.zip" "$(APP_NAME).app"
	@echo "✅ 构建完成！"
	@echo "📍 应用位置: $(BUILT_APP_PATH)"
	@echo "📦 分发包位置: $(DIST_ZIP)"

# 构建应用（无签名版本，用于 CI）
build-unsigned:
	@echo "🔨 构建 $(PROJECT_NAME) 应用 (无签名版本, 架构: $(ARCH_SUFFIX))..."
	@mkdir -p $(BUILD_DIR)
	xcodebuild \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA_PATH)-$(ARCH_SUFFIX) \
		-destination 'platform=macOS,arch=$(ARCH_SUFFIX)' \
		ARCHS=$(ARCH_SUFFIX) \
		ONLY_ACTIVE_ARCH=NO \
		build \
		SYMROOT=$(BUILD_DIR) \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO
	@echo "🧹 清理扩展属性..."
	@xattr -cr "$(BUILT_APP_PATH)"
	@echo "📦 打包分发版本..."
	@cd "$(BUILD_DIR)/$(CONFIGURATION)" && zip -r "$(PROJECT_NAME)-unsigned.zip" "$(APP_NAME).app"
	@echo "✅ 构建完成！"
	@echo "📍 应用位置: $(BUILT_APP_PATH)"
	@echo "📦 分发包位置: $(DIST_ZIP)"

# 安装应用到 /Applications
install-app: build
	@echo "📦 安装 $(PROJECT_NAME) 到 /Applications..."
	@if [ -d "$(INSTALL_PATH)" ]; then \
		echo "⚠️  发现已安装的版本，正在删除..."; \
		sudo rm -rf "$(INSTALL_PATH)"; \
	fi
	@if [ -d "$(BUILT_APP_PATH)" ]; then \
		sudo cp -R "$(BUILT_APP_PATH)" /Applications/; \
		echo "✅ $(PROJECT_NAME) 已成功安装到 /Applications!"; \
		echo "🚀 您可以从 Launchpad 或 Applications 文件夹启动应用"; \
	else \
		echo "❌ 错误: 找不到构建的应用文件 $(BUILT_APP_PATH)"; \
		echo "💡 请先运行 'make build' 构建应用"; \
		exit 1; \
	fi

# 更新版本号
version:
	@if [ -z "$(VERSION)" ]; then \
		echo "❌ 请指定版本号: make version VERSION=1.1.0"; \
		exit 1; \
	fi
	@echo "📝 更新版本号到 $(VERSION)..."
	@sed -i '' 's/MARKETING_VERSION = [^;]*/MARKETING_VERSION = $(VERSION)/g' SaveEye.xcodeproj/project.pbxproj
	@echo "✅ 版本号已更新到 $(VERSION)"
	@echo "💡 请运行 'make build' 重新构建应用"

# 清理构建文件
clean:
	@echo "🧹 清理构建文件..."
	@rm -rf $(BUILD_DIR)
	@echo "✅ 清理完成！"

# 创建 DMG 安装包
dmg: build
	@echo "📦 创建 DMG 安装包..."
	@mkdir -p $(DMG_DIR)
	@cp -R "$(BUILT_APP_PATH)" $(DMG_DIR)/
	@ln -sf /Applications $(DMG_DIR)/Applications
	@echo "Creating DMG for $(VERSION)..."
	@hdiutil create -volname "$(PROJECT_NAME) $(VERSION)" \
		-srcfolder $(DMG_DIR) \
		-ov -format UDZO \
		"$(DMG_PATH)-$(ARCH_SUFFIX).dmg"
	@echo "✅ DMG 创建完成！"
	@echo "📍 $(ARCH_SUFFIX) DMG: $(DMG_PATH)-$(ARCH_SUFFIX).dmg"

# 创建 DMG 安装包（无签名版本，用于 CI）
dmg-unsigned: build-unsigned
	@echo "📦 创建 DMG 安装包 (无签名版本)..."
	@mkdir -p $(DMG_DIR)
	@cp -R "$(BUILT_APP_PATH)" $(DMG_DIR)/
	@ln -sf /Applications $(DMG_DIR)/Applications
	@echo "Creating DMG for $(VERSION)..."
	@hdiutil create -volname "$(PROJECT_NAME) $(VERSION)" \
		-srcfolder $(DMG_DIR) \
		-ov -format UDZO \
		"$(DMG_PATH)-$(ARCH_SUFFIX).dmg"
	@echo "✅ DMG 创建完成！"
	@echo "📍 $(ARCH_SUFFIX) DMG: $(DMG_PATH)-$(ARCH_SUFFIX).dmg"

# 更新 Homebrew Cask
update-homebrew:
	@echo "==> 开始 Homebrew cask 更新流程..."
	@if [ -z "$(GH_PAT)" ]; then \
		echo "❌ 错误: 需要设置 GH_PAT 环境变量"; \
		exit 1; \
	fi

	@echo "==> 当前版本信息:"
	@echo "    - VERSION: $(VERSION)"
	@echo "    - CLEAN_VERSION: $(CLEAN_VERSION)"

	@echo "==> 准备工作目录..."
	@rm -rf tmp && mkdir -p tmp
	
	@echo "==> 下载 DMG 文件..."
	@curl -L -o tmp/$(APP_NAME)-arm64.dmg "https://github.com/samzong/$(APP_NAME)/releases/download/v$(CLEAN_VERSION)/$(APP_NAME)-$(CLEAN_VERSION)-arm64.dmg"
	
	@echo "==> 计算 SHA256 校验和..."
	@ARM64_SHA256=$$(shasum -a 256 tmp/$(APP_NAME)-arm64.dmg | cut -d ' ' -f 1) && echo "    - arm64 SHA256: $$ARM64_SHA256"
	
	@echo "==> 克隆 Homebrew tap 仓库..."
	@cd tmp && git clone https://$(GH_PAT)@github.com/samzong/$(HOMEBREW_TAP_REPO).git
	@cd tmp/$(HOMEBREW_TAP_REPO) && echo "    - 创建新分支: $(BRANCH_NAME)" && git checkout -b $(BRANCH_NAME)

	@echo "==> 更新 cask 文件..."
	@ARM64_SHA256=$$(shasum -a 256 tmp/$(APP_NAME)-arm64.dmg | cut -d ' ' -f 1) && \
	echo "==> 再次确认SHA256: arm64=$$ARM64_SHA256" && \
	cd tmp/$(HOMEBREW_TAP_REPO) && \
	echo "==> 当前目录: $$(pwd)" && \
	echo "==> CASK_FILE路径: $(CASK_FILE)" && \
	if [ -f $(CASK_FILE) ]; then \
		echo "    - 发现现有cask文件，使用sed更新..."; \
		echo "    - cask文件内容 (更新前):"; \
		cat $(CASK_FILE); \
		sed -i '' "s/version \\\".*\\\"/version \\\"$(CLEAN_VERSION)\\\"/g" $(CASK_FILE); \
		echo "    - 更新版本后的cask文件:"; \
		cat $(CASK_FILE); \
		if grep -q "on_arm" $(CASK_FILE); then \
			echo "    - 更新ARM架构SHA256..."; \
			sed -i '' "/on_arm/,/on_intel/ s/sha256 \\\".*\\\"/sha256 \\\"$$ARM64_SHA256\\\"/g" $(CASK_FILE); \
			echo "    - 更新Intel架构SHA256..."; \
			sed -i '' "/on_intel/,/end/ s/sha256 \\\".*\\\"/sha256 \\\"$$X86_64_SHA256\\\"/g" $(CASK_FILE); \
			echo "    - 更新ARM下载URL..."; \
			sed -i '' "s|url \\\".*v#{version}/.*-ARM64.dmg\\\"|url \\\"https://github.com/samzong/$(APP_NAME)/releases/download/v#{version}/$(APP_NAME)-$(CLEAN_VERSION)-arm64.dmg\\\"|g" $(CASK_FILE); \
			echo "    - 最终cask文件内容:"; \
			cat $(CASK_FILE); \
		else \
			echo "❌ 未知的 cask 格式，无法更新 SHA256 值"; \
			exit 1; \
		fi; \
	else \
		echo "    - 未找到cask文件，创建新文件..."; \
		mkdir -p $$(dirname $(CASK_FILE)); \
		echo "    - 使用文本方式创建cask文件..."; \
		echo 'cask "saveeye" do' > $(CASK_FILE); \
		echo '  version "$(CLEAN_VERSION)"' >> $(CASK_FILE); \
		echo '' >> $(CASK_FILE); \
		echo '  if Hardware::CPU.arm?' >> $(CASK_FILE); \
		echo '    url "https://github.com/samzong/$(APP_NAME)/releases/download/v#{version}/$(APP_NAME)-arm64.dmg"' >> $(CASK_FILE); \
		echo '    sha256 "'$$ARM64_SHA256'"' >> $(CASK_FILE); \
		echo '  else' >> $(CASK_FILE); \
		echo '  end' >> $(CASK_FILE); \
		echo '' >> $(CASK_FILE); \
		echo '  name "$(APP_NAME)"' >> $(CASK_FILE); \
		echo '  desc "配置文件管理工具"' >> $(CASK_FILE); \
		echo '  homepage "https://github.com/samzong/$(APP_NAME)"' >> $(CASK_FILE); \
		echo '' >> $(CASK_FILE); \
		echo '  app "$(APP_NAME).app"' >> $(CASK_FILE); \
		echo 'end' >> $(CASK_FILE); \
		echo "    - 检查创建的cask文件:"; \
		cat $(CASK_FILE) || echo "❌ 无法读取cask文件"; \
	fi
	
	@echo "==> 检查更改..."
	@cd tmp/$(HOMEBREW_TAP_REPO) && \
	if ! git diff --quiet $(CASK_FILE); then \
		echo "    - 检测到更改，创建 pull request..."; \
		git add $(CASK_FILE); \
		git config user.name "GitHub Actions"; \
		git config user.email "actions@github.com"; \
		git commit -m "chore: update $(APP_NAME) to v$(CLEAN_VERSION)"; \
		git push -u origin $(BRANCH_NAME); \
		echo "    - 准备创建PR数据..."; \
		pr_data=$$(printf '{\"title\":\"chore: update %s to v%s\",\"body\":\"Auto-generated PR\\\\n- Version: %s\\\\n- x86_64 SHA256: %s\\\\n- arm64 SHA256: %s\",\"head\":\"%s\",\"base\":\"main\"}' \
			"$(APP_NAME)" "$(CLEAN_VERSION)" "$(CLEAN_VERSION)" "$$X86_64_SHA256" "$$ARM64_SHA256" "$(BRANCH_NAME)"); \
		echo "    - PR数据: $$pr_data"; \
		curl -X POST \
			-H "Authorization: token $(GH_PAT)" \
			-H "Content-Type: application/json" \
			https://api.github.com/repos/samzong/$(HOMEBREW_TAP_REPO)/pulls \
			-d "$$pr_data"; \
		echo "✅ Pull request 创建成功"; \
	else \
		echo "❌ cask 文件中没有检测到更改"; \
		exit 1; \
	fi

	@echo "==> 清理临时文件..."
	@rm -rf tmp
	@echo "✅ Homebrew cask 更新流程完成"

# 显示帮助信息
help:
	@echo "SaveEye 构建工具使用说明："
	@echo ""
	@echo "可用命令："
	@echo "  make build           - 构建 SaveEye 应用 (开发者签名版本)"
	@echo "  make build-unsigned  - 构建应用 (无签名版本，用于 CI/发布)"
	@echo "  make install-app     - 构建并安装应用到 /Applications"
	@echo "  make dmg             - 创建 DMG 安装包 (开发者签名版本, 可用 ARCH=x86_64/arm64 指定架构)"
	@echo "  make dmg-unsigned    - 创建 DMG 安装包 (无签名版本，用于发布, 可用 ARCH=x86_64/arm64 指定架构)"
	@echo "  make update-homebrew - 更新 Homebrew Cask (暂时不可用)"
	@echo "  make version         - 更新版本号 (需要 VERSION 参数)"
	@echo "  make clean           - 清理构建文件"
	@echo "  make help            - 显示此帮助信息"
	@echo ""
	@echo "📝 注意事项："
	@echo "  • install-app 需要管理员权限 (sudo)"
	@echo "  • 安装前会自动删除已存在的旧版本"
	@echo "  • 构建文件存储在 ./build 目录中"
	@echo "  • DMG 包仅支持 arm64 架构 (Apple Silicon)"
	@echo ""
	@echo "🚀 快速开始："
	@echo "  make install-app          # 一键构建并安装 (本地使用)"
	@echo "  make dmg-unsigned         # 创建无签名 DMG (用于发布)"
	@echo "  make version VERSION=1.1.0 # 更新版本号"

# 声明伪目标
.PHONY: build build-unsigned install-app dmg dmg-unsigned update-homebrew version clean help

.DEFAULT_GOAL := help