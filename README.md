## 环境配置
#### 下载代码 & pod install

## 实现步骤：
#### 1、界面框架：布局使用 SwiftUI，GoogleMapView 用于管理地图事件和渲染。
#### 2、位置管理：通过 LocationManager 获取并实时更新当前位置。
#### 3、路线规划：在地图上选择目的地后，调用 Google Maps API 获取规划的骑行路线并显示。
#### 4、路径信息：通过底部的 Text 实时显示已骑行距离、剩余距离及预估时间。
#### 5、实时更新：随着用户位置的变化，实时更新 actualPath 路径，绘制实际骑行路线，同时通过 Google Maps API 重新规划剩余路线。
#### 6、到达提示：接近目的地时，底部 Text 会显示额外提示。
#### 7、骑行重置：点击“结束骑行”后，清空所有数据及地图信息，支持重新选择目的地并开始新骑行。

## 优化点
#### 1、更新策略优化：支持真机验证骑行路径的实时更新逻辑。可进一步优化更新策略，减少对 Google Maps API 的频繁调用，提高效率并降低网络消耗。
#### 2、测试与实际场景差异：当前测试中通过模拟器虚拟定位进行位置更新，与实际骑行路线存在一定差异。后续可在真实骑行环境中进行进一步验证和优化。
#### 3、用户体验优化：临近目的地时可提升提示体验，同时将实际骑行路线转换为图片形式，生成定制化的骑行结果页，展示路线图并附带本次骑行的核心数据。

## 效果图：
#### （红色是目的地、蓝色是当前路线、绿色为骑行路径）
![Image text](./result/start.png)
![Image text](./result/riding1.png)
![Image text](./result/riding2.png)
