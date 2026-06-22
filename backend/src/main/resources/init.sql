-- ============================================================
-- MindDef 数据库初始化脚本
-- 包含：建表 + 索引 + 测试数据
-- 使用方法：在 minddef 数据库中执行此脚本
-- ============================================================

CREATE DATABASE IF NOT EXISTS minddef DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE minddef;

-- ============================================================
-- 1. 用户表 (user)
-- ============================================================
DROP TABLE IF EXISTS focus_session;
DROP TABLE IF EXISTS task;
DROP TABLE IF EXISTS user;

CREATE TABLE user (
    id          BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',
    username    VARCHAR(16)     NOT NULL                 COMMENT '用户名，4-16位字母数字下划线',
    password    VARCHAR(128)    NOT NULL                 COMMENT 'BCrypt 加密密码',
    nickname    VARCHAR(32)     DEFAULT NULL             COMMENT '昵称',
    created_at  DATETIME        NOT NULL DEFAULT NOW()   COMMENT '注册时间',
    PRIMARY KEY (id),
    UNIQUE KEY idx_user_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- ============================================================
-- 2. 事项表 (task)
-- ============================================================
CREATE TABLE task (
    id              BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',
    user_id         BIGINT          NOT NULL                 COMMENT '所属用户',
    content         VARCHAR(256)    NOT NULL                 COMMENT '事项内容',
    importance      INT             NOT NULL                 COMMENT '重要性 0-100',
    urgency         INT             NOT NULL                 COMMENT '紧急性 0-100',
    quadrant        TINYINT         NOT NULL                 COMMENT '象限 1:立刻做 2:计划做 3:简化做 4:不做',
    deadline        DATE            DEFAULT NULL             COMMENT '截止日期',
    source          TINYINT         NOT NULL DEFAULT 1       COMMENT '来源 1:手动 2:AI识别 3:引导',
    status          TINYINT         NOT NULL DEFAULT 0       COMMENT '状态 0:待办 1:进行中 2:完成 3:已删除',
    scheduled_date  DATE            DEFAULT NULL             COMMENT '计划日期(②象限)',
    created_at      DATETIME        NOT NULL DEFAULT NOW()   COMMENT '创建时间',
    completed_at    DATETIME        DEFAULT NULL             COMMENT '完成时间',
    PRIMARY KEY (id),
    KEY idx_task_user_id (user_id),
    KEY idx_task_user_quadrant (user_id, quadrant),
    KEY idx_task_user_status (user_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='事项表';

-- ============================================================
-- 3. 专注记录表 (focus_session)
-- ============================================================
CREATE TABLE focus_session (
    id          BIGINT      NOT NULL AUTO_INCREMENT  COMMENT '主键',
    task_id     BIGINT      NOT NULL                 COMMENT '关联事项',
    duration    INT         NOT NULL                 COMMENT '专注时长(秒)',
    completed   TINYINT     NOT NULL DEFAULT 0       COMMENT '0:未完成 1:完成',
    started_at  DATETIME    NOT NULL                 COMMENT '开始时间',
    PRIMARY KEY (id),
    KEY idx_focus_task_id (task_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='专注记录表';

-- ============================================================
-- 4. FAQ 知识库表 (faq)  — 用于 AI 知识库评分项
-- ============================================================
CREATE TABLE faq (
    id          BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',
    category    VARCHAR(32)     NOT NULL                 COMMENT '分类(如:使用指南/技术问题/账户问题)',
    question    VARCHAR(256)    NOT NULL                 COMMENT '问题',
    answer      TEXT            NOT NULL                 COMMENT '答案',
    created_at  DATETIME        NOT NULL DEFAULT NOW()   COMMENT '创建时间',
    PRIMARY KEY (id),
    KEY idx_faq_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='FAQ知识库表';

-- ============================================================
-- 5. 测试数据
-- ============================================================

-- 测试用户（密码均为 BCrypt 加密的 "123456"，由 BcryptUtil 生成）
INSERT INTO user (username, password, nickname) VALUES
('admin',  '$2a$10$slYdrbZtP4/L6dU6nnjS..uDHV08RvmR4yOq5PwHNNKDHBS24hRrO', '管理员'),
('demo',   '$2a$10$slYdrbZtP4/L6dU6nnjS..uDHV08RvmR4yOq5PwHNNKDHBS24hRrO', 'Demo用户');

-- admin 的测试事项（覆盖 4 个象限 + 3 种来源）
INSERT INTO task (user_id, content, importance, urgency, quadrant, deadline, source, status, scheduled_date, created_at) VALUES
-- ① 象限：立刻做
(1, '写年终总结报告',             80, 90, 1, '2026-06-30', 1, 0, NULL,                NOW()),
(1, '修复登录页面bug',            85, 75, 1, '2026-06-25', 1, 1, NULL,                NOW()),
(1, '准备明天项目答辩PPT',        90, 95, 1, '2026-06-23', 2, 0, NULL,                NOW()),
-- ② 象限：计划做
(1, '学习鸿蒙ArkTS状态管理',      75, 30, 2, NULL,         1, 0, '2026-07-01',        NOW()),
(1, '重构后端异常处理模块',        70, 25, 2, NULL,         1, 0, '2026-07-05',        NOW()),
-- ③ 象限：简化做
(1, '回复群消息',                 30, 80, 3, NULL,         1, 0, NULL,                NOW()),
(1, '整理上周会议纪要',            40, 70, 3, '2026-06-23', 1, 2, NULL,                NOW()),
-- ④ 象限：不做
(1, '刷短视频',                   10, 10, 4, NULL,         1, 3, NULL,                NOW()),

-- demo 的测试事项
(2, '完成高数作业',               70, 85, 1, '2026-06-24', 1, 0, NULL,                NOW()),
(2, '阅读《代码整洁之道》',        65, 40, 2, NULL,         1, 0, '2026-06-28',        NOW()),
(2, '取快递',                     25, 60, 3, NULL,         1, 2, NULL,                NOW()),
(2, '看综艺节目',                 15, 20, 4, NULL,         1, 3, NULL,                NOW()),
(2, '设计个人博客首页',           55, 55, 1, NULL,         2, 0, NULL,                NOW());

-- 专注记录（admin 的任务）
INSERT INTO focus_session (task_id, duration, completed, started_at) VALUES
(1, 1500, 1, '2026-06-22 09:00:00'),    -- 25分钟，完成
(1, 1200, 0, '2026-06-22 14:30:00'),    -- 20分钟，未完成
(2, 1800, 1, '2026-06-21 10:00:00');     -- 30分钟，完成

-- FAQ 知识库数据（≥10 条）
INSERT INTO faq (category, question, answer) VALUES
('使用指南',  'MindDef是什么？',                   'MindDef 是一款基于艾森豪威尔矩阵的决策型任务管理应用。它通过重要性×紧急性两个维度，帮你判断每件事该立刻做、计划做、简化做还是不做。'),
('使用指南',  '如何创建任务？',                     '有三种方式：1) 手动输入——填写内容后拖动滑块设定重要性和紧急性；2) 粘贴识别——粘贴一段文本让AI自动拆分为事项；3) 问答引导——回答两个问题自动判定象限。'),
('使用指南',  '四象限分别代表什么？',               '① 立刻做：重要且紧急，需马上处理；② 计划做：重要但不紧急，应排入日程；③ 简化做：不重要但紧急，可快速处理或委托；④ 不做：不重要不紧急，考虑放弃。'),
('使用指南',  '如何修改事项的象限？',               '长按任务卡片，在弹出菜单中选择"移动到其他象限"，然后选择目标象限即可。'),
('使用指南',  '番茄钟怎么用？',                     '在①象限点击事项进入专注页，系统会自动开始25分钟倒计时。专注期间请保持专注，完成后点击"完成"按钮记录本次专注。'),
('使用指南',  'AI识别功能如何使用？',               '在首页点击"+"按钮，选择"粘贴识别"，将你的文本（如聊天记录、会议纪要）粘贴进去，点击"AI识别"，系统会自动提取事项并预判重要性和紧急性。'),
('使用指南',  '统计数据怎么看？',                   '底部切换到"统计"标签页，可以看到累计事项数、完成数、放弃数，以及各象限的占比分布图。'),
('账户问题',  '忘记密码怎么办？',                   '当前版本暂不支持密码找回功能。如有需要，请联系管理员重置密码。'),
('账户问题',  '如何修改昵称？',                     '在"我的"页面，点击昵称栏即可修改。昵称最长 32 个字符。'),
('技术问题',  '为什么AI识别失败？',                 'AI 识别依赖 DeepSeek 大模型服务，可能因网络波动或 API 配额耗尽导致失败。请稍后重试，或使用手动输入或问答引导方式创建任务。每用户每分钟最多调用 10 次 AI 识别。'),
('技术问题',  '登录时提示Token过期怎么办？',        'Token 有效期为 24 小时。过期后系统会自动跳转到登录页面，重新登录即可获取新 Token。'),
('最佳实践',  '如何判断一件事的重要性？',           '可以问自己：这件事和我的长期目标有关吗？直接相关→重要，间接有帮助→一般，没什么关系→不重要。使用问答引导模式可以让系统帮你判断。'),
('最佳实践',  '如何判断一件事的紧急性？',           '可以问自己：这件事今天不做会怎样？有严重后果→紧急，有点麻烦但能补救→一般，没什么影响→不紧急。');
