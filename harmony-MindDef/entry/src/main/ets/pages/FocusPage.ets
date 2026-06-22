/**
 * 番茄钟专注页面
 *
 * 25 分钟倒计时，完成后标记任务完成
 */
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { post } from '../utils/HttpUtil';

@Entry
@Component
struct FocusPage {
  @State taskId: number = 0;
  @State taskContent: string = '';
  @State totalSeconds: number = 25 * 60;    // 25 分钟
  @State remainSeconds: number = 25 * 60;
  @State isRunning: boolean = false;
  @State sessionId: number = 0;
  @State isComplete: boolean = false;
  private timerId: number = -1;

  // ── 初始化 ──

  onPageShow(): void {
    let params: Record<string, Object> = router.getParams() as Record<string, Object>;
    if (params) {
      this.taskId = params['taskId'] as number;
      this.taskContent = params['taskContent'] as string;
    }
  }

  onPageHide(): void {
    this.stopTimer();
  }

  // ── 格式化显示 ──
  get displayMin(): string {
    let m: number = Math.floor(this.remainSeconds / 60);
    return m < 10 ? '0' + m : '' + m;
  }

  get displaySec(): string {
    let s: number = this.remainSeconds % 60;
    return s < 10 ? '0' + s : '' + s;
  }

  get progress(): number {
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
    let startData: Record<string, number> = { 'taskId': this.taskId };
    let data: object | null = await post('/api/focus/start', startData);
    if (data) {
      this.sessionId = (data as Record<string, number>)['id'];
      this.startTimer();
    }
  }

  async doEnd(completed: boolean): Promise<void> {
    this.stopTimer();
    let duration: number = this.totalSeconds - this.remainSeconds;
    let endData: Record<string, number> = {
      'sessionId': this.sessionId,
      'duration': duration,
      'completed': completed ? 1 : 0
    };
    let data: object | null = await post('/api/focus/end', endData);
    if (data) {
      promptAction.showToast({ message: completed ? '专注完成!' : '已放弃', duration: 1000 });
      router.back();
    }
  }

  // ── UI ──

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('← 返回')
          .fontSize(14)
          .fontColor('#4a90d9')
          .onClick(() => {
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
      Text(this.taskContent)
        .fontSize(16)
        .fontColor('#333')
        .maxLines(2)
        .textAlign(TextAlign.Center)
        .width('80%')
        .margin({ top: 40 })

      // 倒计时圆圈
      Column() {
        Text(this.displayMin + ':' + this.displaySec)
          .fontSize(56)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isRunning ? '#e74c3c' : '#4a90d9')

        // 进度条
        Progress({
          value: this.progress,
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
