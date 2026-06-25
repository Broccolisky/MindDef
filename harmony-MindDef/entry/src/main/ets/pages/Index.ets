/**
 * MindDef 首页 —— 四象限看板
 *
 * 2×2 网格展示四个象限任务，TabBar 切换象限/助手/我的
 */
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { isLoggedIn, getNickname } from '../utils/TokenUtil';
import { get, post, put, del } from '../utils/HttpUtil';
import { TaskModel, getQuadrantInfo, QuadrantInfo } from '../model/TaskModel';
import { TaskCard } from '../components/TaskCard';
import { IconLabel } from '../components/IconLabel';
import { StatsPage } from './StatsPage';
import { AiChatPage } from './AiChatPage';

@Entry
@Component
struct Index {
  @State @Watch('onTabChange') currentTab: number = 0;
  @State isLogin: boolean = false;
  @State tasks: TaskModel[] = [];
  @State loading: boolean = true;
  @State isDragging: boolean = false;
  @State dragTask: TaskModel | null = null;
  @State isSearching: boolean = false;
  @State searchText: string = '';
  @State nickname: string = '';
  @State statsRefreshKey: number = 0;
  // selectedTask/showActionMenu 已移除 —— handleLongPress 直接调用 AlertDialog

  // 四个象限元数据（按数轴排列：横轴=紧迫度左低右高，纵轴=重要度上高下低）
  //  ②(左上)  ①(右上)
  //  ④(左下)  ③(右下)
  private quadrants: QuadrantInfo[] = [
    getQuadrantInfo(2),
    getQuadrantInfo(1),
    getQuadrantInfo(4),
    getQuadrantInfo(3)
  ];

  // ──────────── 生命周期 ────────────

  onPageShow(): void {
    this.checkLogin();
  }

  onTabChange(): void {
    // "我的" Tab 现在是索引 2（0=象限, 1=助手, 2=我的）
    if (this.currentTab === 2) {
      this.statsRefreshKey++;
    }
  }

  async checkLogin(): Promise<void> {
    let loggedIn: boolean = await isLoggedIn();
    if (!loggedIn) {
      router.replaceUrl({ url: 'pages/LoginPage' });
    } else {
      this.isLogin = true;
      let nick: string = await getNickname();
      this.nickname = nick || '用户';
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
      this.statsRefreshKey++;
    } finally {
      this.loading = false;
    }
  }

  /**
   * 获取指定象限的任务
   */
  getTasksByQuadrant(quadrant: number): TaskModel[] {
    let result: TaskModel[] = [];
    let keyword: string = this.searchText.trim().toLowerCase();
    for (let i = 0; i < this.tasks.length; i++) {
      let task: TaskModel = this.tasks[i];
      if (task.quadrant === quadrant) {
        if (keyword === '' || task.content.toLowerCase().indexOf(keyword) !== -1) {
          result.push(task);
        }
      }
    }
    return result;
  }

  // ──────────── 象限交互 ────────────

  handleTaskTap(task: TaskModel): void {
    // 所有象限统一：进入编辑页
    AppStorage.setOrCreate('edit_taskId', task.id ?? 0);
    AppStorage.setOrCreate('edit_taskContent', task.content ?? '');
    AppStorage.setOrCreate('edit_importance', task.importance ?? 50);
    AppStorage.setOrCreate('edit_urgency', task.urgency ?? 50);
    AppStorage.setOrCreate('edit_deadline', task.deadline ?? '');
    AppStorage.setOrCreate('edit_source', task.source ?? 1);
    AppStorage.setOrCreate('edit_repeatMode', task.repeatMode ?? 0);
    router.pushUrl({ url: 'pages/SliderCreatePage' });
  }

  handleLongPress(task: TaskModel): void {
    // 捕获引用，避免闭包中 selectedTask 被 null 化
    let capturedTask: TaskModel = task;
    AlertDialog.show({
      title: '操作',
      message: capturedTask.content,
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
      primaryButton: {
        value: '编辑',
        action: () => {
          router.pushUrl({ url: 'pages/SliderCreatePage', params: { taskId: capturedTask.id } });
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {}
      },
      buttons: [
        {
          value: '番茄钟',
          action: () => {
            AppStorage.setOrCreate('focus_taskId', capturedTask.id ?? 0);
            AppStorage.setOrCreate('focus_taskContent', capturedTask.content ?? '');
            router.pushUrl({ url: 'pages/FocusPage' });
          }
        },
        {
          value: '移到①立刻做',
          action: () => { this.moveToQuadrant(capturedTask, 1); }
        },
        {
          value: '移到②计划做',
          action: () => { this.moveToQuadrant(capturedTask, 2); }
        },
        {
          value: '移到③简化做',
          action: () => { this.moveToQuadrant(capturedTask, 3); }
        },
        {
          value: '移到④不做',
          action: () => { this.moveToQuadrant(capturedTask, 4); }
        },
        {
          value: '删除',
          fontColor: '#e74c3c',
          action: () => { this.deleteTask(capturedTask); }
        }
      ]
    });
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
    await del('/api/task/' + task.id);
    promptAction.showToast({ message: '已删除', duration: 1000 });
    await this.loadTasks();
  }

  async showScheduleDialog(task: TaskModel): Promise<void> {
    let selectedDate: Date = task.scheduledDate ? new Date(task.scheduledDate) : new Date();
    DatePickerDialog.show({
      start: new Date(),
      end: new Date(new Date().getFullYear() + 2, 11, 31),
      selected: selectedDate,
      lunar: false,
      onAccept: (value: DatePickerResult) => {
        let m: number = value.month! + 1;  // month 0-indexed
        let month: string = m < 10 ? '0' + m : String(m);
        let day: string = (value.day! < 10 ? '0' + value.day : String(value.day));
        let dateStr: string = value.year + '-' + month + '-' + day;
        this.saveSchedule(task, dateStr);
      }
    });
  }

  async saveSchedule(task: TaskModel, dateStr: string): Promise<void> {
    let scheduleData: Record<string, string> = { 'scheduledDate': dateStr };
    let data: object | null = await put('/api/task/' + task.id + '/schedule', scheduleData);
    if (data) {
      promptAction.showToast({ message: '已排程 ' + dateStr, duration: 1500 });
      await this.loadTasks();
    }
  }

  // ──────────── 拖拽删除 ────────────

  /**
   * 拖拽时跟随手指的预览卡片
   */
  @Builder
  buildDragPreview() {
    Column() {
      Text(this.dragTask?.content || '')
        .fontSize(13)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('#ffffff')
        .borderRadius(8)
        .shadow({ radius: 6, color: '#40000000' })
    }
  }

  /**
   * 拖拽 → 番茄钟区域（上方）
   */
  @Builder
  buildTomatoDropZone() {
    Column() {
      Image($r('app.media.icon_tomato'))
        .width(36)
        .height(36)
        .fillColor('#ffffff')
      Text('番茄钟')
        .fontSize(12)
        .fontColor('#ffffff')
        .margin({ top: 2 })
    }
    .width('45%')
    .height(64)
    .backgroundColor('#e74c3c')
    .borderRadius(16)
    .justifyContent(FlexAlign.Center)
    .opacity(0.88)
    .position({ x: '50%', y: '3%' })
    .shadow({ radius: 10, color: '#60000000' })
    .onDrop((event: DragEvent) => {
      if (this.dragTask !== null) {
        let task: TaskModel = this.dragTask;
        AppStorage.setOrCreate('focus_taskId', task.id ?? 0);
        AppStorage.setOrCreate('focus_taskContent', task.content ?? '');
        this.isDragging = false;
        this.dragTask = null;
        router.pushUrl({ url: 'pages/FocusPage' });
      }
    })
  }

  /**
   * 拖拽 → 完成区域（下方左）
   */
  @Builder
  buildCompleteDropZone() {
    Column() {
      Image($r('app.media.icon_check'))
        .width(32)
        .height(32)
        .fillColor('#ffffff')
      Text('完成')
        .fontSize(12)
        .fontColor('#ffffff')
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .height(64)
    .backgroundColor('#27ae60')
    .borderRadius({ topLeft: 16, bottomLeft: 16 })
    .justifyContent(FlexAlign.Center)
    .onDrop((event: DragEvent) => {
      if (this.dragTask !== null) {
        let task: TaskModel = this.dragTask;
        this.isDragging = false;
        this.dragTask = null;
        this.quickComplete(task);
      }
    })
  }

  /**
   * 拖拽 → 删除区域（下方右）
   */
  @Builder
  buildDeleteDropZone() {
    Column() {
      Image($r('app.media.icon_trash'))
        .width(32)
        .height(32)
        .fillColor('#ffffff')
      Text('删除')
        .fontSize(12)
        .fontColor('#ffffff')
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .height(64)
    .backgroundColor('#e74c3c')
    .borderRadius({ topRight: 16, bottomRight: 16 })
    .justifyContent(FlexAlign.Center)
    .onDrop((event: DragEvent) => {
      if (this.dragTask !== null) {
        let task: TaskModel = this.dragTask;
        this.isDragging = false;
        this.dragTask = null;
        this.deleteTask(task);
      }
    })
  }


  // ──────────── 构建界面 ────────────

  build() {
    if (this.isLogin) {
      Stack() {
        Column() {
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
                  // ── 功能栏 ──
                  if (this.isSearching) {
                    Row() {
                      TextInput({ placeholder: '搜索任务…' })
                        .layoutWeight(1)
                        .height(36)
                        .fontSize(15)
                        .backgroundColor('#f5f5f5')
                        .borderRadius(8)
                        .onChange((v: string) => { this.searchText = v; })

                      Image($r('app.media.icon_close'))
                        .width(18)
                        .height(18)
                        .fillColor('#999')
                        .padding({ left: 10, right: 4 })
                        .onClick(() => {
                          this.isSearching = false;
                          this.searchText = '';
                        })
                    }
                    .width('100%')
                    .padding({ left: 16, right: 16, top: 10, bottom: 8 })
                    .backgroundColor('#ffffff')
                  } else {
                    Row() {
                      IconLabel({
                        icon: $r('app.media.icon_brain'),
                        label: '脑袋def',
                        iconSize: 22,
                        fontSize: 18,
                        fontColor: '#333',
                        iconColor: '#4a90d9',
                        fontWeight: FontWeight.Bold,
                        spacing: 6
                      })

                      Blank()

                      Image($r('app.media.icon_search'))
                        .width(32)
                        .height(32)
                        .padding({ left: 8, right: 4 })
                        .onClick(() => { this.isSearching = true; })
                    }
                    .width('100%')
                    .padding({ left: 16, right: 16, top: 12, bottom: 10 })
                    .backgroundColor('#ffffff')
                  }

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

            // ── Tab 2: 助手 ──
            TabContent() {
              AiChatPage()
            }

            // ── Tab 3: 我的 ──
            TabContent() {
              Column() {
                // 用户信息行
                Row() {
                  Image($r('app.media.icon_user'))
                    .width(32)
                    .height(32)
                    .fillColor('#4a90d9')
                    .margin({ right: 10 })

                  Text(this.nickname || '用户')
                    .fontSize(17)
                    .fontColor('#333')
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1)

                  Image($r('app.media.icon_forward'))
                    .width(16)
                    .height(16)
                    .fillColor('#999')
                }
                .width('100%')
                .padding({ left: 20, right: 20, top: 64, bottom: 14 })
                .backgroundColor('#ffffff')
                .onClick(() => {
                  router.pushUrl({ url: 'pages/ProfilePage' });
                })
                .hitTestBehavior(HitTestMode.Block)

                Divider()

                // 统计（弹性空间）
                Column() {
                  StatsPage({ refreshKey: this.statsRefreshKey })
                }
                .layoutWeight(1)

                // 版本号
                Text('v0.8.1')
                  .fontSize(12)
                  .fontColor('#bbb')
                  .padding({ bottom: 8 })
              }
              .alignItems(HorizontalAlign.Center)
              .width('100%')
              .height('100%')
              .backgroundColor('#f8f8f8')
            }
          }
          .width('100%')
          .layoutWeight(1)
          .barHeight(0)       // 隐藏原生 TabBar
          .barPosition(BarPosition.End)

          // ── 自定义底部栏：象限 | 助手 | ＋ | 我的 ──
          Row() {
            Text('象限')
              .fontSize(15)
              .fontWeight(this.currentTab === 0 ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.currentTab === 0 ? '#4a90d9' : '#999')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .padding({ top: 12, bottom: 12 })
              .onClick(() => { this.currentTab = 0; })

            Text('助手')
              .fontSize(15)
              .fontWeight(this.currentTab === 1 ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.currentTab === 1 ? '#4a90d9' : '#999')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .padding({ top: 12, bottom: 12 })
              .onClick(() => { this.currentTab = 1; })

            // ＋ 创建按钮
            Button('+')
              .width(48)
              .height(48)
              .fontSize(26)
              .fontWeight(FontWeight.Lighter)
              .backgroundColor('#4a90d9')
              .fontColor('#ffffff')
              .borderRadius(24)
              .shadow({ radius: 6, color: '#604a90d9' })
              .margin({ bottom: 8 })
              .onClick(() => {
                router.pushUrl({ url: 'pages/SliderCreatePage' });
              })

            Text('我的')
              .fontSize(15)
              .fontWeight(this.currentTab === 2 ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.currentTab === 2 ? '#4a90d9' : '#999')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .padding({ top: 12, bottom: 12 })
              .onClick(() => { this.currentTab = 2; })
          }
          .width('100%')
          .backgroundColor('#ffffff')
          .padding({ left: 16, right: 16, bottom: 8 })
        }
        .width('100%')
        .height('100%')

        // ── 拖拽操作区（拖拽中浮现）──
        if (this.isDragging) {
          this.buildTomatoDropZone();
          Row() {
            this.buildCompleteDropZone();
            this.buildDeleteDropZone();
          }
          .width('88%')
          .position({ x: '6%', y: '90%' })
        }
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
              onMenuTap: (t: TaskModel) => { this.handleLongPress(t); }
            })
          }
          .draggable(true) // 全象限支持拖拽删除
          .onDragStart((event: DragEvent) => {
            this.isDragging = true;
            this.dragTask = task;
            return this.buildDragPreview;
          })
          .onDragEnd((event: DragEvent) => {
            this.isDragging = false;
            this.dragTask = null;
          })
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
