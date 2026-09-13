# 上线与收款手册

> 代码这边能做的都做了。这份文档列的是**只有你能做的事**——它们都需要你的账号、
> 你的密钥、你的银行卡。按顺序做完就能收钱。

---

## 0. 立刻做：轮换泄露的 API Key ⚠️

仓库历史里有一个明文的 Gemini API Key（`8989e94` 提交，`lib/config/app_config.dart`）。
代码已经改成从 `--dart-define` 读取，但**历史提交里的那个 key 仍然有效，必须作废**：

1. 打开 Google AI Studio → API Keys → 删除那个 key
2. 新建一个 key，**不要**再写进任何文件
3. 如果仓库是 public，假设 key 已被爬走（GitHub 上有专门扫 key 的机器人）

顺带明白一件事：**客户端里的 key 永远是可以被扒出来的**。`--dart-define` 只是把它
从 git 里挪走，任何人下载 ipa 都能反编译拿到。真正的解法是第 2 步的服务端代理。

---

## 1. 现在就能跑起来

```bash
cd omni_flutter
flutter pub get

# 不带 key 也能跑：命盘、每日运势、塔罗、易经、合盘全部本地计算，离线可用
flutter run

# 带 key 跑，多出 AI 对话
flutter run --dart-define=GEMINI_API_KEY=你的新key

flutter test          # 121 个测试
```

**重要设计**：占卜的核心计算全在设备本地，不依赖任何服务。就算你的 AI 额度用光、
服务挂了，App 依然能用。AI 只负责把算出来的结果写成人话。

---

## 2. 服务端代理（提审前必须做）

需要它的两个理由，缺一不可：

1. **保护 key**：客户端 key 会被扒走，别人用你的额度
2. **验证收据**：`in_app_purchase` 的购买事件在越狱机上可以伪造。现在的
   `StorePurchaseService` 是本地记账的，能被绕过

最省事的方案是 **RevenueCat**（收据验证 + 订阅状态托管，月流水 $2.5k 以内免费）：

- 注册 → 建 App → 填 App Store Connect 的 In-App Purchase Key
- 把 `purchase_service.dart` 里的 `StorePurchaseService` 换成 `purchases_flutter`
  的实现（抽象层已经留好了，`PurchaseService` 那四个方法照着实现即可）
- 好处：不用自己写收据校验、不用管订阅续期/退款/宽限期这些坑

AI 代理用 **Cloudflare Worker** 就够（免费额度每天 10 万次请求）：

```js
export default {
  async fetch(request, env) {
    // 1. 校验调用者身份（RevenueCat webhook 同步过来的订阅状态）
    // 2. 按用户 ID 限流，防止一个人刷爆额度
    // 3. 转发到 Gemini，key 只存在 env.GEMINI_API_KEY
  }
}
```

然后 `flutter build --dart-define=OMNI_API_BASE_URL=https://你的域名`，
App 就会走代理而不是直连模型。

---

## 3. App Store Connect 配置

**商品 ID 必须和 `lib/core/billing/products.dart` 里完全一致**，写错了商店会返回
"product not found"，付费墙上就只剩兜底价格：

| Product ID | 类型 | 价格 | 备注 |
|---|---|---|---|
| `omni.plus.monthly` | 自动续订订阅 | $7.99 | 3 天免费试用 |
| `omni.plus.annual` | 自动续订订阅 | $39.99 | 7 天免费试用 |
| `omni.plus.lifetime` | 非消耗型 | $99.99 | |
| `omni.coins.60` | 消耗型 | $1.99 | |
| `omni.coins.180` | 消耗型 | $4.99 | |
| `omni.coins.400` | 消耗型 | $9.99 | |

两个订阅放进同一个 **Subscription Group**（这样用户能在月付/年付之间升降级）。

还要准备：
- 隐私政策 URL 和服务条款 URL（付费墙上的按钮现在指向占位提示，等页面上线后接上）
- **Privacy Nutrition Label**：目前 App 只在本地存出生信息，不上传。
  接了 AI 代理之后，如实勾选"数据用于 App 功能，不做追踪"
- 至少 3 张 6.7" 截图（今日 / 命盘 / 合盘 这三屏最能说明差异化）

---

## 4. 审核风险与对策

| 风险 | 对策 |
|---|---|
| **4.3 Spam**（星座 App 太多了，苹果批量拒） | 审核备注里直接写清楚：这是唯一把西方本命盘和八字放在同一个命盘里交叉解读的产品，并说明太阳位置用截断 VSOP87 星历、节气用真实黄经反解。差异化要**说出来**，别指望审核员自己发现 |
| **3.1.2 订阅信息不全** | 已做：付费墙上有价格、周期、自动续订说明、Restore、Terms、Privacy |
| **占卜类免责** | 已做：账号页有"仅供娱乐、不构成医疗/法律/财务/心理建议"的声明 |
| **1.4.1 医疗宣称** | 别在文案里写"治疗""缓解焦虑""改善健康"这类词，运势建议不要涉及吃药、看病 |

---

## 5. 最快见到现金流的路径：先上 Web

iOS 提审要等，Apple 抽 30%（小企业计划 15%），还要等 App Store 打款周期。
**Web 版 + Stripe 当天就能收钱，抽成 2.9% + $0.30。**

```bash
flutter build web --dart-define=GEMINI_API_KEY=...
# 部署到 Cloudflare Pages / Vercel，免费
```

注意 `in_app_purchase` 没有 web 实现，Web 版需要在 `chooseService()` 里加一个
Stripe Checkout 的分支。这是目前唯一还没写的收款通路，但抽象层已经留好位置。

策略建议：**Web 先跑起来验证转化率和文案，用真实数据调好价格，再提 iOS**。

---

## 5.5 打开 GitHub Actions（一分钟的事）

`.github/workflows/ci.yaml` 已经加好了（`flutter analyze` + `flutter test`，
Flutter 版本锁 3.24.5），但**这个仓库的 Actions 是关闭的**——文件推上去之后
GitHub 一次运行都没创建。

打开方式：仓库 → Settings → Actions → General → 选 **Allow all actions and
reusable workflows** → Save。

值得花这一分钟：引擎测试是拿真实节气和分至点时刻做基准的。一旦这部分回归，
App 不会崩，只会**悄悄给用户算错星座和月柱**——这种 bug 靠手测发现不了。

---

## 6. 上线后第一件事：埋点

现在一个埋点都没有，等于闭着眼睛调价。至少要知道这四个数：

1. 装机 → 填完出生信息的转化率（这一步流失最多）
2. 付费墙**被哪个功能触发**（决定免费额度该松还是该紧）
3. 付费墙曝光 → 购买的转化率（行业基准 2–5%）
4. D1 / D7 留存

用 PostHog 或 Firebase Analytics，一两个小时能接完。

---

## 7. 还没做的（按优先级）

| 优先级 | 事项 | 为什么 |
|---|---|---|
| P0 | 服务端代理 + 收据验证 | 没有它，key 会被盗刷、订阅能被伪造 |
| P0 | 隐私政策 / 服务条款页面 | 审核必需 |
| P0 | 埋点 | 没数据就没法优化转化 |
| P1 | 分享卡（IG Story 竖版图） | 获客靠这个，成本最低 |
| P1 | 推送（早 8 点运势、节气、水逆） | 留存靠这个 |
| P1 | 流年大运 | 玉币的主力消费点，现在只有价格没有内容 |
| P1 | 许愿墙 / 灵魂匹配 | 真社交需要后端（账号、内容审核），是个独立工程 |
| P2 | 中文本地化 | 引擎已经是中英双语数据，UI 换文案即可 |
| P2 | 真人占卜师市场 | ARPU 最高但重运营 |

---

## 8. 已知的精度边界

诚实记录，免得以后被用户问住：

- **太阳位置 / 节气**：误差小于 1 分钟（8 个公开参考时刻实测，最大 40 秒）
- **月亮位置**：约 0.3°。落在星座边界 0.3° 内的用户可能被算成邻座——
  App 会主动提示"临界"，不会假装确定
- **上升星座**：算法误差可忽略，但用户填的出生时间差 1 分钟就差 0.25°，
  误差主要来自输入而不是计算
- **夏令时**：没有内置历史时区库。出生表单会显示 UTC 偏移并允许手动调整，
  夏令时国家会给出提示。要做到全自动，需要引入 `timezone` 包和 tzdata
