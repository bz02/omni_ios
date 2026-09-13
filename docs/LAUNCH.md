# 上线与收款手册

> 代码这边能做的都做完了，包括服务端。
> 这份文档列的是**只有你能做的事**——它们都需要你的账号、你的密钥、你的银行卡。

---

## 0. 立刻做：轮换泄露的 API Key ⚠️

仓库历史里有一个明文的 Gemini API Key（`8989e94` 提交，`lib/config/app_config.dart`）。
代码早已不再从那里读 key，但**历史提交里的那个仍然有效，必须作废**：

1. Google AI Studio → API Keys → 删除那个 key
2. 新建一个，**只**交给 Cloudflare（`wrangler secret put GEMINI_API_KEY`），不要再进任何文件
3. 如果仓库是 public，假设它已被爬走（GitHub 上有专门扫 key 的机器人）

---

## 1. 现在就能跑

```bash
cd omni_flutter
flutter pub get
flutter run        # 不带任何 key：命盘、运势、塔罗、易经、合盘全部本地计算，离线可用
flutter test       # 166 个测试

cd ../server
node --test        # 31 个测试，不连网
```

**核心设计**：占卜计算全在设备本地。服务挂了、额度用光了，App 照样能用。
AI 只负责把算出来的东西写成人话。

---

## 2. 服务端（已经写好了）

`server/` 是一个 Cloudflare Worker。它一个人干三件事，而这三件事**每一件都是上线阻塞项**：

| 阻塞项 | 为什么必须有服务端 |
|---|---|
| 模型 key | 编进客户端的 key，任何人下载 App 都能反编译扒出来 |
| 付费凭证 | 记在手机上的"已付费"就是 shared_preferences 里的一个数，越狱机随便改 |
| Web 收款 | Web 没有 `in_app_purchase`，而 Stripe Checkout 必须用 secret key 在服务端开单 |

**关键安全设计**：客户端只发一个 **product id**。价格、模式、等级、币数全部在服务端查表。
被改过的客户端能选买哪个商品，别的什么都改不了。

部署：

```bash
cd server
npm install
npx wrangler kv:namespace create ENTITLEMENTS
npx wrangler kv:namespace create RATE
# 把两个 id 填进 wrangler.toml

npx wrangler secret put STRIPE_SECRET_KEY
npx wrangler secret put STRIPE_WEBHOOK_SECRET
npx wrangler secret put GEMINI_API_KEY

npx wrangler deploy
```

Stripe 后台：给 `server/catalogue.mjs` 里的 6 个 product id 各建一个 price，
把 price id 填进 `wrangler.toml`；再建一个 webhook 指向 `/v1/stripe-webhook`，
订阅 `checkout.session.completed`、`customer.subscription.updated`、
`customer.subscription.deleted` 三个事件。

**Webhook 必须配**。不配的话订阅取消了 App 也不会锁——这正是测试里
`a subscription redeemed by code can still be revoked later` 那条守的东西。

---

## 3. Web 版上线（最快见到现金流）

iOS 要等审核，苹果抽 15–30%。**Stripe 抽 2.9% + $0.30，几天到账。**

```bash
cd omni_flutter
flutter build web --release \
  --dart-define=OMNI_API_BASE_URL=https://omni-api.<你的账号>.workers.dev \
  --dart-define=OMNI_WEB_RETURN_URL=https://你的域名 \
  --dart-define=OMNI_ANALYTICS_KEY=<PostHog key，可选>
```

把 `build/web` 部署到 Cloudflare Pages 或 Vercel（都免费），
然后把 `wrangler.toml` 里的 `ALLOWED_ORIGIN` 改成同一个域名。

`ALLOWED_ORIGIN` 同时是 checkout 唯一允许跳回的地址——防止别人把
Stripe 回调变成一个带收据的开放重定向。

**建议顺序：Web 先跑，用真实转化数据把价格和文案调好，再提 iOS。**

---

## 4. App Store Connect（iOS）

商品 ID 必须和 `lib/core/billing/products.dart`、`server/catalogue.mjs` 完全一致：

| Product ID | 类型 | 价格 | 备注 |
|---|---|---|---|
| `omni.plus.monthly` | 自动续订订阅 | $7.99 | 3 天试用 |
| `omni.plus.annual` | 自动续订订阅 | $39.99 | 7 天试用 |
| `omni.plus.lifetime` | 非消耗型 | $99.99 | |
| `omni.coins.60` | 消耗型 | $1.99 | |
| `omni.coins.180` | 消耗型 | $4.99 | |
| `omni.coins.400` | 消耗型 | $9.99 | |

两个订阅放进同一个 Subscription Group。另外还要：隐私政策 URL、服务条款 URL、
Privacy Nutrition Label（出生信息本地存储；接了服务端后如实勾选"用于 App 功能，不做追踪"）、
3 张 6.7" 截图（今日 / 命盘 / 合盘 最能说明差异化）。

⚠️ **iOS 必须走 StoreKit**。苹果会拒绝把数字商品绕开内购的 App——
`chooseService()` 已经按平台分流，别改。

---

## 5. 审核风险

| 风险 | 对策 |
|---|---|
| **4.3 Spam**（星座 App 太多，苹果批量拒） | 审核备注里直接写：这是唯一把西方本命盘和八字放进同一命盘交叉解读的产品，太阳位置用截断 VSOP87 星历、节气由真实黄经反解。**差异化要说出来**，别指望审核员自己发现 |
| 3.1.2 订阅信息不全 | 已做：付费墙上有价格、周期、自动续订说明、Restore、Terms、Privacy |
| 占卜类免责 | 已做：账号页有"仅供娱乐，不构成医疗/法律/财务/心理建议" |
| 1.4.1 医疗宣称 | 文案别出现"治疗""缓解焦虑""改善健康"，运势建议别涉及吃药看病 |

---

## 6. 埋点（已接好，缺一个 key）

`lib/core/analytics/` 是 provider 无关的事件层，四个决定收入的数已经埋好了：

1. `onboarding_started` → `onboarding_completed`（流失最多的一步，并区分有没有出生时间）
2. `quota_exhausted` + `paywall_shown`（带 trigger：哪个功能触发的，决定免费额度该松还是该紧）
3. `purchase_started` → `purchase_completed` / `purchase_failed`（行业基准 2–5%）
4. `reading_viewed`

默认是 no-op。加上 `--dart-define=OMNI_ANALYTICS_KEY=<PostHog project key>` 就开始上报，
只发匿名 install id，**不发任何出生信息**。

---

## 7. 还没做的（按优先级）

| 优先级 | 事项 | 为什么 |
|---|---|---|
| P0 | 隐私政策 / 服务条款页面 | 审核必需；付费墙上现在是占位提示 |
| P1 | 分享卡（IG Story 竖版图） | 获客靠这个，成本最低 |
| P1 | 邮箱 magic-link | 见下面的"已知限制" |
| P1 | 推送（早 8 点运势、节气、水逆） | 留存靠这个 |
| P1 | 深度报告（deepDive，180 币） | 唯一还剩「有价格没内容」的 SKU |
| P2 | 许愿墙 / 灵魂匹配 | 真社交需要账号体系和内容审核，是独立工程 |
| P2 | 中文本地化 | 引擎数据已经是中英双语，UI 换文案即可 |

---

## 8. 已知限制（诚实记录）

**跨设备恢复**。为了不在用户看到第一份命盘之前就要求注册，结账是匿名的，
订阅绑在设备上，Stripe 的 session id 就是收据。账号页有"我在另一台设备付过款"
可以用收据里的恢复码找回。但**删了 App 又没留恢复码，订阅就只能人工去 Stripe 后台查**。
邮箱 magic-link 是正解，是有收入之后第一个该补的东西。

**精度**：
- 太阳位置 / 节气：误差 < 1 分钟（8 个公开参考时刻实测，最大 40 秒）
- 月亮位置：约 0.3°，落在星座边界 0.3° 内的用户可能算成邻座——App 会主动提示"临界"
- 上升星座：算法误差可忽略，误差主要来自用户填的出生时间
- **夏令时没有内置历史时区库**。出生表单会显示 UTC 偏移并允许手动调整，
  夏令时国家会给提示。要全自动需要引入 `timezone` 包和 tzdata
