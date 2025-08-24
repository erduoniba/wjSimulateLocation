# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个iOS虚拟定位应用，用于在开发调试时模拟设备位置。项目使用Objective-C编写，通过GPX文件配置模拟位置。

## 构建和运行

### 编译项目
```bash
# 清理构建
xcodebuild clean -project wjSimulateLocation.xcodeproj -scheme wjSimulateLocation

# Debug构建
xcodebuild build -project wjSimulateLocation.xcodeproj -scheme wjSimulateLocation -configuration Debug

# Release构建
xcodebuild build -project wjSimulateLocation.xcodeproj -scheme wjSimulateLocation -configuration Release
```

### 运行项目
1. 在Xcode中打开 `wjSimulateLocation.xcodeproj`
2. 配置定位模拟：Product -> Scheme -> Edit Scheme -> Options -> Default Location，选择 `Location.gpx` 文件
3. 确保 "Allow Location Simulation" 选项已勾选
4. 选择真机或模拟器运行

## 核心架构

### 坐标系转换
项目的核心功能是坐标系转换，支持以下坐标系之间的相互转换：
- **WGS-84**: GPS和iOS定位使用的国际标准坐标系
- **GCJ-02**: 中国国内地图服务（高德、腾讯）使用的加密坐标系
- **BD-09**: 百度地图专用坐标系

主要转换类：`wjLocationTransform` (wjSimulateLocation/wjLocationTransform.h/.m)
- 提供各坐标系之间的双向转换方法
- 初始化时传入经纬度，调用相应方法获取目标坐标系的坐标

### GPX文件配置
位置模拟通过 `Location.gpx` 文件配置：
- 支持单点定位或多点路径模拟
- 格式：包含经纬度、名称和可选时间戳的waypoint节点
- 文件位置：wjSimulateLocation/Location.gpx

### 使用流程
1. 从高德地图等服务获取目标位置的坐标（通常是GCJ-02坐标系）
2. 使用 `wjLocationTransform` 将坐标转换为WGS-84（iOS使用的坐标系）
3. 将转换后的坐标填入 `Location.gpx` 文件
4. 在Xcode Scheme中配置使用该GPX文件进行位置模拟

## 动态修改位置

### 方法1：运行时实时修改（推荐）
**无需重启Xcode，无需重新选择GPX文件**

1. **LocationSimulationManager** - 核心位置模拟管理器
   - 使用Method Swizzling拦截CLLocationManager的定位方法
   - 支持实时更新位置，立即生效
   - 支持路线模拟和单点定位

2. **LocationControlViewController** - 可视化控制界面
   - 实时输入经纬度更新位置
   - 支持WGS-84、GCJ-02、BD-09坐标系自动转换
   - 地图点击选择位置
   - 预设城市快速切换（北京、上海、广州）
   - 路线模拟功能

3. **使用方式**
   ```objc
   // 直接更新位置（代码方式）
   [[LocationSimulationManager sharedManager] updateSimulatedLocationWithLatitude:39.904200 
                                                                         longitude:116.407396];
   
   // 或通过UI控制台操作
   // 点击"打开位置控制台"按钮即可
   ```

### 方法2：使用Xcode Debug菜单
1. **使用Xcode Debug菜单**（应用运行时）
   - Debug -> Simulate Location -> 选择不同的GPX文件
   - 可以在预设的多个GPX文件之间切换

2. **GPX文件类型**
   - 单点定位：Location.gpx, Beijing.gpx, Shanghai.gpx
   - 路线模拟：Route.gpx（包含多个waypoint，模拟移动）

3. **动态生成GPX文件**
   - 使用 `GPXGenerator` 类可以在运行时生成新的GPX文件
   - 生成的文件保存在应用Documents目录
   - 需要重新在Xcode中配置使用新生成的GPX文件

### GPX文件格式说明
- 单点定位：包含一个waypoint，定位在固定位置
- 路线模拟：包含多个waypoint，按时间顺序模拟移动
- 时间元素：控制移动速度，不提供则使用固定速度

## 重要说明
- 此方法仅用于开发调试，不能用于App Store发布版本
- 可以修改微信、QQ等应用的定位
- 断开调试后定位恢复正常
- 需要开发者账号才能在真机上使用位置模拟功能
- 修改GPX文件后需要重新运行应用或在Debug菜单中重新选择