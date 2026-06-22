/**
 * 滑块创建页面
 *
 * 用户输入内容 + 拖动两个滑块 → 实时显示象限判定和建议
 */
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { post } from '../utils/HttpUtil';
import { calcQuadrant, getAdvice, getImportanceLabel, getUrgencyLabel } from '../model/TaskModel';

@Entry
@Component
struct SliderCreatePage {
  @State content: string = '';
  @State importance: number = 50;
  @State urgency: number = 50;
  @State deadline: string = '';
  @State loading: boolean = false;
  @State showDeadline: boolean = false;   // 折叠面板状态

  // 实时计算象限
  get quadrant(): number {
    return calcQuadrant(this.importance, this.urgency);
  }

  get advice(): string {
    return getAdvice(this.quadrant);
  }

  get importanceLabel(): string {
    return getImportanceLabel(this.importance);
  }

  get urgencyLabel(): string {
    return getUrgencyLabel(this.urgency);
  }

  onPageShow(): void {
    // 读取引导页"微调"传入的参数
    let params: Record<string, Object> = router.getParams() as Record<string, Object>;
    if (params) {
      if (params['content'] !== undefined) this.content = params['content'] as string;
      if (params['importance'] !== undefined) this.importance = params['importance'] as number;
      if (params['urgency'] !== undefined) this.urgency = params['urgency'] as number;
    }
  }

  build() {
    Column() {
      // ── 标题栏 ──
      Row() {
        Text('← 返回')
          .fontSize(14)
          .fontColor('#4a90d9')
          .onClick(() => { router.back(); })

        Blank()

        Text('新建事项')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)

        Blank()

        Text('    ')
          .fontSize(14)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Divider()

      // ── 内容输入 ──
      TextInput({ placeholder: '输入事项内容...' })
        .width('100%')
        .height(48)
        .fontSize(16)
        .backgroundColor('#f8f8f8')
        .borderRadius(8)
        .margin({ left: 20, right: 20, top: 20 })
        .onChange((value: string) => {
          this.content = value;
        })

      // ── 滑块区 ──
      Column() {
        // 重要性滑块
        Row() {
          Text('重要性')
            .fontSize(14)
            .fontColor('#666')
            .width(60)

          Slider({
            value: this.importance,
            min: 0,
            max: 100,
            step: 1
          })
            .blockColor('#4a90d9')
            .trackColor('#e0e0e0')
            .layoutWeight(1)
            .onChange((value: number) => {
              this.importance = value;
            })

          Text(this.importanceLabel)
            .fontSize(13)
            .fontColor('#4a90d9')
            .width(70)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .margin({ top: 24 })

        // 紧急性滑块
        Row() {
          Text('紧急性')
            .fontSize(14)
            .fontColor('#666')
            .width(60)

          Slider({
            value: this.urgency,
            min: 0,
            max: 100,
            step: 1
          })
            .blockColor('#e74c3c')
            .trackColor('#e0e0e0')
            .layoutWeight(1)
            .onChange((value: number) => {
              this.urgency = value;
            })

          Text(this.urgencyLabel)
            .fontSize(13)
            .fontColor('#e74c3c')
            .width(70)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .margin({ top: 16 })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })

      // ── 截止日期（折叠） ──
      Column() {
        Row() {
          Text('📅 截止日期（可选）')
            .fontSize(13)
            .fontColor('#999')
            .onClick(() => {
              this.showDeadline = !this.showDeadline;
            })
        }
        .width('100%')
        .margin({ top: 16, left: 20, right: 20 })

        if (this.showDeadline) {
          TextInput({ placeholder: 'yyyy-MM-dd，如 2026-06-30' })
            .width('100%')
            .height(44)
            .fontSize(14)
            .backgroundColor('#f8f8f8')
            .borderRadius(8)
            .margin({ left: 20, right: 20, top: 8 })
            .onChange((value: string) => {
              this.deadline = value;
            })
        }
      }

      // ── 实时判定卡片 ──
      Row() {
        Column() {
          Text('当前判定：' + this.quadrant + ' ' + this.advice)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333')

          Text('建议：' + this.advice)
            .fontSize(12)
            .fontColor('#999')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 象限指示
        Text('' + this.quadrant)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4a90d9')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 14, bottom: 14 })
      .backgroundColor('#f0f7ff')
      .borderRadius(10)
      .margin({ left: 20, right: 20, top: 20 })

      Blank()

      // ── 提交按钮 ──
      Button(this.loading ? '创建中...' : '放入象限')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(this.canSubmit() ? '#4a90d9' : '#ccc')
        .borderRadius(24)
        .margin({ left: 32, right: 32, bottom: 40 })
        .enabled(this.canSubmit() && !this.loading)
        .onClick(() => {
          this.doCreate();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }

  canSubmit(): boolean {
    return this.content.trim() !== '';
  }

  async doCreate(): Promise<void> {
    this.loading = true;
    try {
      let reqData: Record<string, Object> = {
        'content': this.content.trim(),
        'importance': this.importance,
        'urgency': this.urgency,
        'source': 1
      };
      if (this.deadline.trim()) {
        reqData['deadline'] = this.deadline.trim();
      }

      let data: object | null = await post('/api/task', reqData);
      if (data) {
        promptAction.showToast({ message: '创建成功', duration: 1000 });
        router.back();
      }
    } finally {
      this.loading = false;
    }
  }
}
