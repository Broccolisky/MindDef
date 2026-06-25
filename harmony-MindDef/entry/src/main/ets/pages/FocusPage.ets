/**
 * 番茄钟专注页面
 *
 * 25 分钟倒计时，完成后标记任务完成
 */
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { post } from '../utils/HttpUtil';
import { IconLabel } from '../components/IconLabel';

@Entry
@Component
struct FocusPage {
  @State taskId: number = 0;
  @State taskContent: string = '';
  @State focusMinutes: number = 25;            // 可调节的专注时长（分钟）
  @State totalSeconds: number = 25 * 60;
  @State remainSeconds: number = 25 * 60;
  @State isRunning: boolean = false;
  @State sessionId: number = 0;
  @State isComplete: boolean = false;
  @State starting: boolean = false;            // 防重复点击
  @State navigating: boolean = false;          // 防重复导航
  @State isEditingTime: boolean = false;       // 是否正在编辑时长
  @State editMinutes: string = '25';           // 编辑中的分钟数
  private timerId: number = -1;

  // ── 初始化 ──

  aboutToAppear(): void {
    // 通过 AppStorage 读取参数（绕过 router.getParams 在 API 24 的序列化 bug）
    let tid: number | undefined = AppStorage.get('focus_taskId') as number | undefined;
    if (tid !== undefined && tid !== null) {
      this.taskId = tid;
    }
    let tc: string | undefined = AppStorage.get('focus_taskContent') as string | undefined;
    if (tc !== undefined && tc !== null) {
      this.taskContent = tc;
    }
  }

  onPageHide(): void {
    if (this.isRunning && this.sessionId > 0) {
      this.doEnd(false);  // 后台切走→自动结束专注（放弃）
    } else {
      this.stopTimer();
    }
  }

  // ── 时长调节 ──

  /**
   * 更新专注时长（滑块或手动输入调用）
   */
  applyFocusMinutes(minutes: number): void {
    let clamped: number = minutes < 1 ? 1 : (minutes > 120 ? 120 : minutes);
    this.focusMinutes = clamped;
    this.totalSeconds = clamped * 60;
    this.remainSeconds = clamped * 60;
  }

  /**
   * 点击时间文字 → 弹出数字键盘编辑
   */
  startEditTime(): void {
    if (this.isRunning || this.isComplete) return;
    this.editMinutes = String(this.focusMinutes);
    this.isEditingTime = true;
  }

  /**
   * 确认编辑
   */
  confirmEditTime(): void {
    let val: number = parseInt(this.editMinutes);
    if (!isNaN(val) && val >= 1 && val <= 120) {
      this.applyFocusMinutes(val);
    }
    this.isEditingTime = false;
  }

  // ── 格式化显示（不用 get 访问器 —— ArkTS API 24 getter 不响应 @State）──
  formatMin(): string {
    let m: number = Math.floor(this.remainSeconds / 60);
    return m < 10 ? '0' + m : '' + m;
  }

  formatSec(): string {
    let s: number = this.remainSeconds % 60;
    return s < 10 ? '0' + s : '' + s;
  }

  formatProgress(): number {
    return (this.totalSeconds - this.remainSeconds) / this.totalSeconds * 100;
  }

  // ── 计时器 ──

  startTimer(): void {
    this.isRunning = true;
    this.timerId = setInterval(() => {
      if (this.remainSeconds > 0) {
        this.remainSeconds--;
      } else {
        this.stopTimer();
        this.isComplete = true;
        this.doEnd(true);  // 倒计时结束→自动完成
      }
    }, 1000);
  }

  stopTimer(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    this.isRunning = false;
  }

  // ── API 调用 ──

  async doStart(): Promise<void> {
    if (this.starting) return;  // 防重复点击
    this.starting = true;
    try {
      let startData: Record<string, number> = { 'taskId': this.taskId };
      let data: object | null = await post('/api/focus/start', startData);
      if (data) {
        let idVal: number | undefined = (data as Record<string, number>)['id'];
        if (idVal !== undefined && idVal !== null) {
          this.sessionId = idVal;
          this.startTimer();
        }
      }
    } finally {
      this.starting = false;
    }
  }

  async doEnd(completed: boolean): Promise<void> {
    if (this.navigating) return;  // 防重复导航
    this.stopTimer();
    this.navigating = true;
    try {
      let duration: number = this.totalSeconds - this.remainSeconds;
      let endData: Record<string, number> = {
        'sessionId': this.sessionId,
        'duration': duration,
        'completed': completed ? 1 : 0
      };
      let data: object | null = await post('/api/focus/end', endData);
      if (data) {
        promptAction.showToast({ message: completed ? '专注完成!' : '已放弃', duration: 1000 });
      }
    } finally {
      router.back();  // 无论 API 成败都返回
    }
  }

  // ── UI ──

  build() {
    Column() {
      // 标题栏
      Row() {
        IconLabel({
          icon: $r('app.media.icon_back'),
          label: '返回',
          iconSize: 16,
          fontSize: 14,
          iconColor: '#4a90d9',
          fontColor: '#4a90d9',
          spacing: 2
        })
          .onClick(() => {
            if (this.navigating) return;
            if (this.isRunning) {
              this.doEnd(false);
            } else {
              router.back();
            }
          })

        Blank()

        Text('番茄钟')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)

        Blank()
        Text('    ').fontSize(14)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Divider()

      // 任务内容
      Text((this.taskContent && this.taskContent !== 'undefined') ? this.taskContent : '（无任务名）')
        .fontSize(16)
        .fontColor('#333')
        .maxLines(2)
        .textAlign(TextAlign.Center)
        .width('80%')
        .margin({ top: 40 })

      // 倒计时圆圈
      Column() {
        // 时间显示（非运行态可点击编辑）
        if (this.isEditingTime) {
          Row() {
            TextInput({ text: this.editMinutes, placeholder: '分钟' })
              .type(InputType.Number)
              .width(80)
              .height(48)
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
              .backgroundColor('#f0f0f0')
              .borderRadius(8)
              .maxLength(3)
              .onChange((value: string) => {
                this.editMinutes = value;
              })
              .onSubmit(() => {
                this.confirmEditTime();
              })

            Text('分钟')
              .fontSize(18)
              .fontColor('#999')
              .margin({ left: 8 })
          }
          .justifyContent(FlexAlign.Center)
        } else {
          Text(this.formatMin() + ':' + this.formatSec())
            .fontSize(56)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isRunning ? '#e74c3c' : '#4a90d9')
            .onClick(() => { this.startEditTime(); })
        }

        // 时长调节滑块（非运行态显示）
        if (!this.isRunning && !this.isComplete && this.sessionId === 0) {
          Column() {
            Row() {
              Text('1分钟')
                .fontSize(11)
                .fontColor('#bbb')

              Slider({
                value: this.focusMinutes,
                min: 1,
                max: 120,
                step: 1
              })
                .blockColor('#4a90d9')
                .trackColor('#e0e0e0')
                .layoutWeight(1)
                .margin({ left: 8, right: 8 })
                .onChange((value: number) => {
                  this.applyFocusMinutes(value);
                })

              Text('120分钟')
                .fontSize(11)
                .fontColor('#bbb')
            }
            .width('80%')
            .alignItems(VerticalAlign.Center)

            Text(this.focusMinutes + ' 分钟')
              .fontSize(14)
              .fontColor('#4a90d9')
              .fontWeight(FontWeight.Medium)
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 12 })
        }

        // 进度圆环
        Progress({
          value: this.formatProgress(),
          total: 100,
          type: ProgressType.Ring
        })
          .width(160)
          .height(160)
          .margin({ top: 20 })
          .color('#4a90d9')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 60 })

      // 按钮区
      if (!this.isRunning && !this.isComplete && this.sessionId === 0) {
        Button('开始专注')
          .width('60%')
          .height(48)
          .fontSize(16)
          .backgroundColor('#e74c3c')
          .borderRadius(24)
          .margin({ top: 60 })
          .enabled(!this.starting)
          .onClick(() => { this.doStart(); })
      }

      if (this.isRunning) {
        Row() {
          Button('完成')
            .height(48)
            .fontSize(16)
            .backgroundColor('#27ae60')
            .borderRadius(24)
            .margin({ right: 12 })
            .layoutWeight(1)
            .onClick(() => { this.doEnd(true); })

          Button('放弃')
            .height(48)
            .fontSize(16)
            .backgroundColor('#f0f0f0')
            .fontColor('#e74c3c')
            .borderRadius(24)
            .margin({ left: 12 })
            .layoutWeight(1)
            .onClick(() => { this.doEnd(false); })
        }
        .width('80%')
        .margin({ top: 60 })
      }

      if (this.isComplete) {
        Button('完成并返回')
          .width('60%')
          .height(48)
          .fontSize(16)
          .backgroundColor('#27ae60')
          .borderRadius(24)
          .margin({ top: 60 })
          .onClick(() => { this.doEnd(true); })
      }

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }
}
