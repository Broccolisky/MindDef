/**
 * 任务数据模型（对应后端 Task 实体）
 */
export class TaskModel {
  id: number = 0;
  userId: number = 0;
  content: string = '';
  importance: number = 0;
  urgency: number = 0;
  quadrant: number = 1;
  deadline: string | null = null;
  source: number = 1;
  status: number = 0;
  scheduledDate: string | null = null;
  createdAt: string = '';
  completedAt: string | null = null;
}

/**
 * 象限信息
 */
export class QuadrantInfo {
  index: number;       // 1-4
  title: string;       // 立刻做 / 计划做 / 简化做 / 不做
  color: string;       // 背景色
  action: string;      // 核心交互提示
  taskCount: number;   // 该象限任务数

  constructor(index: number, title: string, color: string, action: string) {
    this.index = index;
    this.title = title;
    this.color = color;
    this.action = action;
    this.taskCount = 0;
  }
}

/**
 * 象限数据
 */
export function getQuadrantInfo(quadrant: number): QuadrantInfo {
  switch (quadrant) {
    case 1:
      return new QuadrantInfo(1, '立刻做', '#ffe0e0', '点击开始番茄钟');
    case 2:
      return new QuadrantInfo(2, '计划做', '#e0f0ff', '点击排日程');
    case 3:
      return new QuadrantInfo(3, '简化做', '#fff5e0', '点击快速完成');
    case 4:
      return new QuadrantInfo(4, '不做', '#e8e8e8', '左滑删除');
    default:
      return new QuadrantInfo(1, '', '', '');
  }
}

/**
 * 根据重要性和紧迫性计算象限
 */
export function calcQuadrant(importance: number, urgency: number): number {
  if (importance > 50 && urgency > 50) return 1;
  if (importance > 50) return 2;
  if (urgency > 50) return 3;
  return 4;
}

/**
 * 根据象限获取建议文案
 */
export function getAdvice(quadrant: number): string {
  switch (quadrant) {
    case 1: return '现在就做';
    case 2: return '排进日程';
    case 3: return '能简化就简化';
    case 4: return '考虑放弃';
    default: return '';
  }
}

/**
 * 滑块标签
 */
export function getImportanceLabel(val: number): string {
  if (val <= 25) return '不重要';
  if (val <= 50) return '一般';
  if (val <= 75) return '重要';
  return '非常重要';
}

export function getUrgencyLabel(val: number): string {
  if (val <= 25) return '不紧急';
  if (val <= 50) return '有点急';
  if (val <= 75) return '比较急';
  return '非常紧急';
}
