/**
 * 视图页 — 以月历形式展示任务分布（含重复任务展开）
 *
 * 调用 GET /api/calendar?year=X&month=X 获取数据
 */
import { get } from '../utils/HttpUtil';
import { TaskModel } from '../model/TaskModel';

/** 日期格数据 */
class DayCell {
  day: number = 0;
  dateStr: string = '';
  count: number = 0;
  isToday: boolean = false;
}

@Component
export struct CalendarPage {
  @Prop @Watch('onRefresh') refreshKey: number = 0;
  @State calendarData: Record<string, TaskModel[]> = {};
  @State currentYear: number = new Date().getFullYear();
  @State currentMonth: number = new Date().getMonth() + 1;
  @State selectedDate: string = '';
  @State weeks: DayCell[][] = [];
  @State loading: boolean = false;

  onRefresh(): void {
    this.loadCalendar();
  }

  aboutToAppear(): void {
    let today: Date = new Date();
    let ts: string = today.getFullYear() + '-' +
      String(today.getMonth() + 1).padStart(2, '0') + '-' +
      String(today.getDate()).padStart(2, '0');
    this.selectedDate = ts;
    this.loadCalendar();
  }

  async loadCalendar(): Promise<void> {
    this.loading = true;
    try {
      let data: object | null = await get(
        '/api/calendar?year=' + this.currentYear + '&month=' + this.currentMonth
      );
      if (data) {
        this.calendarData = data as Record<string, TaskModel[]>;
      }
    } finally {
      this.loading = false;
      this.buildCalendar();
    }
  }

  buildCalendar(): void {
    let year: number = this.currentYear;
    let month: number = this.currentMonth;
    let todayStr: string = new Date().getFullYear() + '-' +
      String(new Date().getMonth() + 1).padStart(2, '0') + '-' +
      String(new Date().getDate()).padStart(2, '0');

    let firstDay: Date = new Date(year, month - 1, 1);
    let lastDay: Date = new Date(year, month, 0);

    let startDow: number = firstDay.getDay();
    if (startDow === 0) startDow = 7;

    let totalDays: number = lastDay.getDate();
    let newWeeks: DayCell[][] = [];
    let currentWeek: DayCell[] = [];

    for (let i = 1; i < startDow; i++) {
      currentWeek.push(new DayCell());
    }

    for (let d = 1; d <= totalDays; d++) {
      let m: string = String(month).padStart(2, '0');
      let day: string = String(d).padStart(2, '0');
      let dateStr: string = year + '-' + m + '-' + day;

      let tasks: TaskModel[] | undefined = this.calendarData[dateStr];
      let count: number = (tasks !== undefined && tasks !== null) ? tasks.length : 0;

      let cell: DayCell = new DayCell();
      cell.day = d;
      cell.dateStr = dateStr;
      cell.count = count;
      cell.isToday = dateStr === todayStr;
      currentWeek.push(cell);

      if (currentWeek.length === 7) {
        newWeeks.push(currentWeek);
        currentWeek = [];
      }
    }

    if (currentWeek.length > 0) {
      while (currentWeek.length < 7) {
        currentWeek.push(new DayCell());
      }
      newWeeks.push(currentWeek);
    }

    this.weeks = newWeeks;
  }

  countTasksOnDate(dateStr: string): number {
    let tasks: TaskModel[] | undefined = this.calendarData[dateStr];
    return (tasks !== undefined && tasks !== null) ? tasks.length : 0;
  }

  getTasksForDate(dateStr: string): TaskModel[] {
    let tasks: TaskModel[] | undefined = this.calendarData[dateStr];
    return (tasks !== undefined && tasks !== null) ? tasks : [];
  }

  changeMonth(delta: number): void {
    let newMonth: number = this.currentMonth + delta;
    let newYear: number = this.currentYear;
    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    } else if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }
    this.currentYear = newYear;
    this.currentMonth = newMonth;
    this.loadCalendar();
  }

  build() {
    Column() {
      // ── 标题栏 ──
      Row() {
        Text('视图')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })
      .backgroundColor('#ffffff')

      Divider()

      // ── 月份切换 ──
      Row() {
        Image($r('app.media.icon_back'))
          .width(20)
          .height(20)
          .fillColor('#4a90d9')
          .onClick(() => { this.changeMonth(-1); })

        Text(this.currentYear + '年' + this.currentMonth + '月')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Image($r('app.media.icon_forward'))
          .width(20)
          .height(20)
          .fillColor('#4a90d9')
          .onClick(() => { this.changeMonth(1); })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 14, bottom: 10 })
      .backgroundColor('#ffffff')

      // ── 星期表头 ──
      Row() {
        ForEach(['一', '二', '三', '四', '五', '六', '日'], (label: string) => {
          Text(label)
            .fontSize(13)
            .fontColor('#999')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding({ top: 6, bottom: 6 })
        })
      }
      .width('100%')
      .padding({ left: 12, right: 12 })
      .backgroundColor('#ffffff')
      .border({ width: { bottom: 1 }, color: '#eee' })

      // ── 日期网格 ──
      if (this.loading) {
        Column() {
          LoadingProgress().width(32).height(32)
          Text('加载中...').fontSize(13).fontColor('#999').margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Column() {
          ForEach(this.weeks, (week: DayCell[]) => {
            Row() {
              ForEach(week, (cell: DayCell) => {
                Column() {
                  if (cell.day > 0) {
                    Text('' + cell.day)
                      .fontSize(14)
                      .fontWeight(cell.isToday ? FontWeight.Bold : FontWeight.Normal)
                      .fontColor(cell.isToday ? '#ffffff' : '#333')
                      .width(28)
                      .height(28)
                      .textAlign(TextAlign.Center)
                      .borderRadius(14)
                      .backgroundColor(cell.isToday ? '#4a90d9' :
                        this.selectedDate === cell.dateStr ? '#e8f0ff' : 'transparent')

                    if (cell.count > 0) {
                      Text('' + cell.count)
                        .fontSize(10)
                        .fontColor('#4a90d9')
                        .fontWeight(FontWeight.Bold)
                    }
                  }
                }
                .layoutWeight(1)
                .height(42)
                .justifyContent(FlexAlign.Center)
                .onClick(() => {
                  if (cell.day > 0) {
                    this.selectedDate = cell.dateStr;
                  }
                })
              })
            }
            .width('100%')
          })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 4 })
        .backgroundColor('#ffffff')
      }

      // ── 选中日期的任务列表 ──
      Divider().margin({ top: 12 })

      Column() {
        Row() {
          Text(this.selectedDate)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333')

          Text('  ' + this.getTasksForDate(this.selectedDate).length + '条任务')
            .fontSize(12)
            .fontColor('#999')
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 8 })

        if (this.getTasksForDate(this.selectedDate).length === 0) {
          Text('当天无任务')
            .fontSize(13)
            .fontColor('#bbb')
            .padding({ top: 20, bottom: 20 })
        } else {
          List() {
            ForEach(this.getTasksForDate(this.selectedDate), (task: TaskModel) => {
              ListItem() {
                this.buildTaskRow(task);
              }
            })
          }
          .width('100%')
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#f8f8f8')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildTaskRow(task: TaskModel) {
    Row() {
      Text('' + task.quadrant)
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor('#ffffff')
        .width(20)
        .height(20)
        .textAlign(TextAlign.Center)
        .backgroundColor(task.quadrant === 1 ? '#e74c3c' :
          task.quadrant === 2 ? '#4a90d9' :
          task.quadrant === 3 ? '#f39c12' : '#999')
        .borderRadius(10)

      Text(task.content)
        .fontSize(14)
        .fontColor('#333')
        .margin({ left: 8 })
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      if (task.status === 2) {
        Text('✓')
          .fontSize(14)
          .fontColor('#27ae60')
          .fontWeight(FontWeight.Bold)
      }

      if (task.repeatMode > 0) {
        Text(task.repeatMode === 1 ? ' 每日' : task.repeatMode === 2 ? ' 工作日' : ' 休息日')
          .fontSize(10)
          .fontColor('#4a90d9')
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 10, bottom: 10 })
  }
}
