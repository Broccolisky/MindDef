# MindDef · 艾森豪威尔矩阵决策型任务管理

> **基于艾森豪威尔矩阵（Eisenhower Matrix）的智能任务管理应用**  
> 市面上的 Todo 解决"记什么"，MindDef 解决"**做什么**"。

---

## 技术栈

| 层级 | 技术 | 版本 |
|------|------|------|
| 前端 | HarmonyOS ArkTS | API 12+ |
| 后端 | Spring Boot | 2.7.18 |
| 数据库 | MySQL | 8.0 |
| ORM | MyBatis-Plus | 3.5.2 |
| 认证 | JWT (jjwt) + BCrypt | jjwt 0.9.1 |
| AI | DeepSeek API | deepseek-v4-flash |
| 接口文档 | Swagger 2 (springfox) | 2.9.2 |
| 参数校验 | javax.validation | — |
| JDK | Java 21 (Amazon Corretto) | — |

---

## 项目结构

```
MindDef__Workspace/
├── MindDef/
│   ├── backend/                 # Spring Boot 后端
│   │   ├── src/main/java/com/naodai/def/
│   │   │   ├── controller/      # 接口层 (6 个)
│   │   │   ├── service/         # 业务层 (6 个)
│   │   │   ├── mapper/          # 数据层 (4 个)
│   │   │   ├── entity/          # 数据库实体 (4 个)
│   │   │   ├── dto/             # 数据传输对象 (13 个)
│   │   │   ├── common/          # 通用模块 (Result/JWT/异常)
│   │   │   ├── config/          # 配置 (CORS/Swagger/拦截器)
│   │   │   └── interceptor/     # JWT 拦截器
│   │   └── src/main/resources/
│   │       ├── application.yml  # 主配置
│   │       └── init.sql         # 建库建表 + 测试数据
│   │
│   └── harmony-MindDef/         # 鸿蒙前端
│       └── entry/src/main/ets/
│           ├── pages/           # 页面 (7 个注册页)
│           ├── components/      # 公共组件 (TaskCard / IconLabel)
│           ├── utils/           # 工具类 (HttpUtil / TokenUtil)
│           └── model/           # 数据模型 (TaskModel)
│
├── deploy/                      # 部署文件
├── README.md                    # 本文件
├── dev_plan.md                  # 开发计划
└── dev_log/                     # 工作留痕 (6 个 Phase)
```

---

## 环境要求

| 工具 | 版本要求 | 说明 |
|------|---------|------|
| JDK | 21+ | 后端运行环境 |
| Maven | 3.6+ | 后端构建工具 |
| MySQL | 8.0+ | 数据库（需提前启动） |
| DevEco Studio | 5.0+ | 鸿蒙前端 IDE |
| Node.js | 18+ | devecocli 依赖 |
| Git | 2.30+ | 版本管理 |

---

## 快速启动

### 1. 克隆项目

```bash
git clone https://github.com/Broccolisky/MindDef.git
cd MindDef__Workspace
```

### 2. 初始化数据库

```bash
# 启动 MySQL 后执行
mysql -u root -p < MindDef/backend/src/main/resources/init.sql
```

### 3. 配置后端

编辑 `MindDef/backend/src/main/resources/application.yml`：

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/minddef?useUnicode=true&characterEncoding=utf-8&...
    username: root          # 修改为你的 MySQL 用户名
    password: root          # 修改为你的 MySQL 密码

deepseek:
  api-key: sk-your-key-here   # 修改为你的 DeepSeek API Key
```

### 4. 启动后端

```bash
cd MindDef/backend
mvn spring-boot:run
# 启动成功 → http://localhost:8080
# Swagger 文档 → http://localhost:8080/swagger-ui.html
```

### 5. 启动前端

用 **DevEco Studio** 打开 `MindDef/harmony-MindDef/` 项目，点击 Run 部署到模拟器或真机。

或使用命令行：

```bash
cd MindDef/harmony-MindDef
devecocli build
devecocli run
```

---

## 演示账号

| 用户名 | 密码 | 说明 |
|--------|------|------|
| `admin` | `123456` | 管理员（含预置测试数据：13 条任务，覆盖四象限） |
| `demo` | `123456` | 演示用户（空数据） |

---

## API 端点一览

共 **17 个接口**，分为 5 组：

### 01-认证（无需 Token）

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/auth/register` | 用户注册 |
| POST | `/api/auth/login` | 用户登录，返回 JWT |

### 02-任务管理

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/task` | 创建任务（手动/引导/AI） |
| GET | `/api/task/list` | 获取任务列表（支持象限/状态筛选） |
| PUT | `/api/task/{id}` | 编辑任务内容 |
| PUT | `/api/task/{id}/quadrant` | 移动象限 |
| PUT | `/api/task/{id}/schedule` | 设置计划日期 |
| PUT | `/api/task/{id}/complete` | 标记完成 |
| DELETE | `/api/task/{id}` | 删除任务（软删除） |

### 03-AI 智能

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/task/ai-parse` | AI 文本解析（粘贴文本→提取事项） |
| POST | `/api/ai/chat` | AI 智能问答（FAQ 优先 + DeepSeek 兜底） |

### 04-番茄钟

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/focus/start` | 开始专注（创建 session） |
| POST | `/api/focus/end` | 结束专注（记录时长 + 状态） |

### 05-个人中心 & 统计

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/user/profile` | 获取个人信息 |
| PUT | `/api/user/nickname` | 修改昵称 |
| PUT | `/api/user/password` | 修改密码 |
| GET | `/api/stats/overview` | 决策统计概览 |

> 完整接口文档：启动后端后访问 http://localhost:8080/swagger-ui.html

---

## 数据库表结构

| 表名 | 说明 | 记录数 | 关键字段 |
|------|------|:---:|---------|
| `user` | 用户表 | 2 | id, username, password(BCrypt), nickname |
| `task` | 任务表 | 13 | id, user_id, content, importance, urgency, quadrant, deadline, source, status |
| `focus_session` | 专注记录表 | 3 | id, task_id, duration, completed, started_at |
| `faq` | FAQ 知识库 | 13 | id, category, question, answer |

**索引**: `idx_user_username`(UNIQUE) / `idx_task_user_id` / `idx_task_user_quadrant`(复合) / `idx_task_user_status` / `idx_focus_task_id`

**状态码**: `0` 待办 / `1` 进行中 / `2` 已完成 / `3` 已放弃（软删除）

**象限判定**: 重要性 > 50 且 紧急性 > 50 → ① | 重要性 > 50 → ② | 紧急性 > 50 → ③ | 否则 → ④

---

## 前端页面

| 页面 | 文件 | 路由 |
|------|------|------|
| 首页(四象限) | `Index.ets` | `pages/Index`（入口，含"我的"Tab） |
| 登录 | `LoginPage.ets` | `pages/LoginPage` |
| 注册 | `RegisterPage.ets` | `pages/RegisterPage` |
| 统一创建页 | `SliderCreatePage.ets` | `pages/SliderCreatePage`（手动+AI+引导入口） |
| 引导创建 | `GuideCreatePage.ets` | `pages/GuideCreatePage`（辅助页，从创建页进入） |
| 番茄钟 | `FocusPage.ets` | `pages/FocusPage` |
| 个人中心 | `ProfilePage.ets` | `pages/ProfilePage`（从"我的"Tab头像进入） |

> 注：AiParsePage 已整合进 SliderCreatePage 的 AI 面板，不再独立注册。共 **7 个注册页面**。

---

## 核心功能

1. **四象限看板** — 2×2 艾森豪威尔矩阵，数轴排列 ②①④③（横轴紧迫左低右高，纵轴重要上高下低）
2. **统一创建页** — 手动双滑块（实时象限判定）+ AI 粘贴识别 + 引导式问答，三合一入口
3. **AI 智能解析** — DeepSeek API 接入，粘贴自然语言文本自动提取事项/评分/象限
4. **AI 知识库问答** — FAQ 关键词匹配优先 → DeepSeek 兜底，频率限制 10 次/分钟
5. **番茄钟** — 1-120 分钟可调专注倒计时，环形进度条，记录专注时长
6. **决策统计** — 累计/完成/放弃 + 四象限分布 + 周/月完成统计
7. **JWT 安全认证** — BCrypt 密码加密、Token 24h 有效期、归属校验（403 拦截越权）

---

## 鸿蒙原生能力

| 能力 | 使用场景 |
|------|---------|
| `@State` / `@Prop` / `@Builder` / `@Watch` | 组件状态管理与 UI 复用 |
| `List` + `ListItem` | 象限任务列表渲染 |
| `Grid` + `GridItem` | 2×2 四象限网格布局 |
| `Tabs` + `TabContent` | 象限/我的 双 Tab 切换 |
| `Progress` (Ring + Linear) | 番茄钟进度环 + 统计分布进度条 |
| `Preferences` | Token 本地持久化存储 |
| `setInterval` / `clearInterval` | 番茄钟倒计时 |
| `AlertDialog` | 操作确认弹窗 |
| `DatePickerDialog` | 截止日期系统选择器 |
| `InputType.Password` | 密码安全输入 |
| `router` (pushUrl/replaceUrl/back) | 页面导航 |

---

## 开发阶段

| Phase | 内容 | 状态 |
|:-----:|------|:---:|
| P0 | 项目初始化（工程骨架 + 建库建表） | ✅ |
| P1 | 登录注册（JWT + BCrypt + 前后端联调） | ✅ |
| P2 | 核心业务（任务 CRUD + 四象限看板） | ✅ |
| P3 | AI 整合（DeepSeek + FAQ 知识库） | ✅ |
| P4 | 扩展功能（番茄钟 + 统计 + 个人中心） | ✅ |
| P5 | 工程规范（Swagger + 代码审查 + 异常处理） | ✅ |
| P6 | 联调测试 + 演示准备 | ✅ |

---

## 已知问题与修复记录

> v0.6.3 已修复：
> - BUG-01: FocusPage 计时器显示 "undefined"（get 访问器 → 普通方法）
> - BUG-05: 滑块标签不响应 `@State` 变化（getter → 直接函数调用）
> - 任务软删除不生效（MyBatis-Plus 逻辑删除冲突 → `deleteById()`）
> - ProfilePage 昵称/密码修改按钮无效（TextInput 缺 `text` 绑定）
> - 象限分布统计不更新（`get distTotal()` → `@State distTotal`）
> - SVG 图标显示为蓝色方块（mask 路径重写为纯 SVG 路径）

---

## 常见问题

**Q: curl 测试中文返回 500？**  
A: Windows Git Bash 的 curl 默认使用 GBK 编码发送中文。使用 Postman 或 DevEco Studio 测试即可。

**Q: 如何重置数据库？**  
A: `DROP DATABASE minddef;` → 重新执行 `init.sql`

**Q: AI 解析无响应？**  
A: 检查 `application.yml` 中 DeepSeek API Key 是否有效，网络是否可达 `api.deepseek.com`

**Q: 模拟器连不上后端？**  
A: 将 `HttpUtil.ets` 中的 `BASE_URL` 改为 `http://10.0.2.2:8080`（模拟器专用地址）

---

> 最后更新：2026-06-26 · MindDef v0.6.3 · GitHub: https://github.com/Broccolisky/MindDef
