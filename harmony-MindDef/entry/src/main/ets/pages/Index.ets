/**
 * MindDef 首页 —— 四象限看板
 *
 * 2×2 网格展示四个象限任务，TabBar 切换统计/我的
 */
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { isLoggedIn } from '../utils/TokenUtil';
import { get, post, put, del } from '../utils/HttpUtil';
import { TaskModel, getQuadrantInfo, QuadrantInfo } from '../model/TaskModel';
import { TaskCard } from '../components/TaskCard';
import { StatsPage } from './StatsPage';
import { ProfilePage } from './ProfilePage';

@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  @State isLogin: boolean = false;
  @State tasks: TaskModel[] = [];
  @State loading: boolean = true;
  @State showCreateMenu: boolean = false;
  @State selectedTask: TaskModel | null = null;
  @State showActionMenu: boolean = false;

  // 四个象限元数据
  private quadrants: QuadrantInfo[] = [
    getQuadrantInfo(1),
    getQuadrantInfo(2),
    getQuadrantInfo(3),
    getQuadrantInfo(4)
  ];

  // ──────────── 生命周期 ────────────

  onPageShow(): void {
    this.checkLogin();
  }

  async checkLogin(): Promise<void> {
    let loggedIn: boolean = await isLoggedIn();
    if (!loggedIn) {
      router.replaceUrl({ url: 'pages/LoginPage' });
    } else {
      this.isLogin = true;
      await this.loadTasks();
    }
  }

  /**
   * 加载任务列表
   */
  async loadTasks(): Promise<void> {
    this.loading = true;
    try {
      let data: object | null = await get('/api/task/list');
      if (data) {
        this.tasks = data as TaskModel[];
      }
    } finally {
      this.loading = false;
    }
  }

  /**
   * 获取指定象限的任务
   */
  getTasksByQuadrant(quadrant: number): TaskModel[] {
    let result: TaskModel[] = [];
    for (let i = 0; i < this.tasks.length; i++) {
      if (this.tasks[i].quadrant === quadrant) {
        result.push(this.tasks[i]);
      }
    }
    return result;
  }

  // ──────────── 象限交互 ────────────

  handleTaskTap(task: TaskModel): void {
    if (task.quadrant === 3) {
      // ③ 象限：快速完成
      this.quickComplete(task);
    } else if (task.quadrant === 1) {
      // ① 象限：跳转番茄钟
      router.pushUrl({
        url: 'pages/FocusPage',
        params: { taskId: task.id, taskContent: task.content }
      });
    } else if (task.quadrant === 2) {
      // ② 象限：排日程
      this.showScheduleDialog(task);
    }
  }

  handleLongPress(task: TaskModel): void {
    this.selectedTask = task;
    this.showActionMenu = true;
  }

  async quickComplete(task: TaskModel): Promise<void> {
    let data: Record<string, Object> | null = await put('/api/task/' + task.id + '/complete') as Record<string, Object> | null;
    if (data) {
      promptAction.showToast({ message: '已完成', duration: 1000 });
      await this.loadTasks();
    }
  }

  async moveToQuadrant(task: TaskModel, targetQuadrant: number): Promise<void> {
    let moveData: Record<string, number> = { 'quadrant': targetQuadrant };
    let data: object | null = await put('/api/task/' + task.id + '/quadrant', moveData);
    if (data) {
      await this.loadTasks();
    }
  }

  async deleteTask(task: TaskModel): Promise<void> {
    let result: object | null = await del('/api/task/' + task.id);
    if (result !== null) {
      promptAction.showToast({ message: '已删除', duration: 1000 });
      await this.loadTasks();
    }
  }

  async showScheduleDialog(task: TaskModel): Promise<void> {
    // 暂用 Toast 代替（Phase 4 实现完整的日期选择器）
    promptAction.showToast({ message: '排程功能将在 Phase 4 实现', duration: 1500 });
  }

  // ──────────── 操作菜单 ────────────

  buildActionMenu(): void {
    if (!this.showActionMenu || !this.selectedTask) {
      return;
    }

    AlertDialog.show({
      title: '操作',
      message: this.selectedTask.content,
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
      primaryButton: {
        value: '编辑',
        action: () => {
          let task: TaskModel | null = this.selectedTask;
          if (task) {
            router.pushUrl({ url: 'pages/SliderCreatePage', params: { taskId: task.id } });
          }
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {}
      },
      buttons: [
        {
          value: '移到①立刻做',
          action: () => { if (this.selectedTask) this.moveToQuadrant(this.selectedTask, 1); }
        },
        {
          value: '移到②计划做',
          action: () => { if (this.selectedTask) this.moveToQuadrant(this.selectedTask, 2); }
        },
        {
          value: '移到③简化做',
          action: () => { if (this.selectedTask) this.moveToQuadrant(this.selectedTask, 3); }
        },
        {
          value: '移到④不做',
          action: () => { if (this.selectedTask) this.moveToQuadrant(this.selectedTask, 4); }
        },
        {
          value: '删除',
          fontColor: '#e74c3c',
          action: () => { if (this.selectedTask) this.deleteTask(this.selectedTask); }
        }
      ]
    });

    this.showActionMenu = false;
    this.selectedTask = null;
  }

  // ──────────── 创建菜单 ────────────

  buildCreateMenu(): void {
    AlertDialog.show({
      title: '创建事项',
      message: '选择创建方式',
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
      primaryButton: {
        value: '📝 手动输入',
        action: () => {
          router.pushUrl({ url: 'pages/SliderCreatePage' });
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {}
      },
      buttons: [
        {
          value: '📋 粘贴识别',
          action: () => {
            router.pushUrl({ url: 'pages/AiParsePage' });
          }
        },
        {
          value: '💬 帮我判断',
          action: () => {
            router.pushUrl({ url: 'pages/GuideCreatePage' });
          }
        }
      ]
    });
  }

  // ──────────── 构建界面 ────────────

  build() {
    if (this.isLogin) {
      Stack() {
        Tabs({ index: this.currentTab }) {
          // ── Tab 1: 象限看板 ──
          TabContent() {
            if (this.loading) {
              Column() {
                LoadingProgress()
                  .width(40)
                  .height(40)
                Text('加载中...')
                  .fontSize(14)
                  .fontColor('#999')
                  .margin({ top: 8 })
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
            } else {
              Column() {
                // 2×2 象限网格
                Grid() {
                  ForEach(this.quadrants, (qi: QuadrantInfo, index: number) => {
                    GridItem() {
                      this.buildQuadrantCell(qi);
                    }
                  })
                }
                .columnsTemplate('1fr 1fr')
                .rowsTemplate('1fr 1fr')
                .width('100%')
                .height('100%')
                .padding(8)
                .backgroundColor('#f5f5f5')
              }
              .width('100%')
              .height('100%')
            }
          }
          .tabBar('象限')

          // ── Tab 2: 统计 ──
          TabContent() {
            StatsPage()
          }
          .tabBar('统计')

          // ── Tab 3: 我的 ──
          TabContent() {
            ProfilePage()
          }
          .tabBar('我的')
        }
        .width('100%')
        .height('100%')
        .barPosition(BarPosition.End)

        // ── 悬浮创建按钮 ──
        Button('+')
          .width(56)
          .height(56)
          .fontSize(28)
          .fontWeight(FontWeight.Lighter)
          .backgroundColor('#4a90d9')
          .fontColor('#ffffff')
          .borderRadius(28)
          .position({ x: '80%', y: '82%' })
          .shadow({ radius: 8, color: '#33000000' })
          .onClick(() => {
            this.buildCreateMenu();
          })
      }
      .width('100%')
      .height('100%')
    }
  }

  /**
   * 单个象限格子
   */
  @Builder
  buildQuadrantCell(qi: QuadrantInfo) {
    Column() {
      // 标题栏
      Row() {
        Text('●')
          .fontSize(12)
          .fontColor(qi.color === '#ffe0e0' ? '#e74c3c' :
                     qi.color === '#e0f0ff' ? '#4a90d9' :
                     qi.color === '#fff5e0' ? '#f39c12' : '#999')
        Text(qi.title)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .margin({ left: 4 })

        Blank()

        Text('' + this.getTasksByQuadrant(qi.index).length)
          .fontSize(11)
          .fontColor('#999')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor('#f0f0f0')
          .borderRadius(10)
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 6, bottom: 4 })

      // 任务列表
      List() {
        if (this.getTasksByQuadrant(qi.index).length === 0) {
          ListItem() {
            Text('暂无事项')
              .fontSize(12)
              .fontColor('#bbb')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 20, bottom: 20 })
          }
        }
        ForEach(this.getTasksByQuadrant(qi.index), (task: TaskModel) => {
          ListItem() {
            TaskCard({
              task: task,
              onTap: (t: TaskModel) => { this.handleTaskTap(t); },
              onLongPress: (t: TaskModel) => { this.handleLongPress(t); }
            })
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 8, right: 8, bottom: 4 })
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(qi.color)
    .borderRadius(10)
    .padding(4)
  }
}
