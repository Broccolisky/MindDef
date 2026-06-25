/**
 * AI 识别页面
 *
 * 用户粘贴文本 → AI 分析 → 展示识别结果卡片列表 → 逐条确认/修改/全部确认
 */
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { post } from '../utils/HttpUtil';
import { AiTaskItem } from '../model/TaskModel';

@Entry
@Component
struct AiParsePage {
  @State rawText: string = '';
  @State loading: boolean = false;
  @State items: AiTaskItem[] = [];
  @State hasResult: boolean = false;

  build() {
    Column() {
      // ── 标题栏 ──
      Row() {
        Text('← 返回')
          .fontSize(14)
          .fontColor('#4a90d9')
          .onClick(() => { router.back(); })

        Blank()

        Text('AI 粘贴识别')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)

        Blank()

        Text('    ')
          .fontSize(14)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Divider()

      if (!this.hasResult) {
        // ── 输入阶段 ──
        Column() {
          Text('📋 粘贴内容：')
            .fontSize(14)
            .fontColor('#666')
            .width('100%')
            .margin({ top: 20, bottom: 8 })

          TextArea({ placeholder: '将聊天记录、会议纪要等内容粘贴到这里...\n最多 2000 字' })
            .width('100%')
            .height(180)
            .fontSize(15)
            .backgroundColor('#f8f8f8')
            .borderRadius(10)
            .padding(12)
            .onChange((value: string) => {
              this.rawText = value;
            })

          Button(this.loading ? '⏳ AI 正在分析...' : '🤖 AI 识别')
            .width('100%')
            .height(48)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .backgroundColor(this.canParse() ? '#4a90d9' : '#ccc')
            .borderRadius(24)
            .margin({ top: 24, left: 32, right: 32 })
            .enabled(this.canParse() && !this.loading)
            .onClick(() => { this.doParse(); })

          if (this.loading) {
            LoadingProgress()
              .width(36)
              .height(36)
              .margin({ top: 16 })

            Text('AI 正在分析中，请稍候...')
              .fontSize(13)
              .fontColor('#999')
              .margin({ top: 8 })
          }
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 20, right: 20 })

      } else {
        // ── 结果展示阶段 ──
        Column() {
          Row() {
            Text('🤖 识别结果：')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')

            Blank()

            Text('' + this.items.length + ' 条')
              .fontSize(12)
              .fontColor('#999')
              .padding({ left: 10, right: 10, top: 3, bottom: 3 })
              .backgroundColor('#f0f0f0')
              .borderRadius(10)
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 8 })

          // 结果列表
          List() {
            ForEach(this.items, (item: AiTaskItem, index: number) => {
              ListItem() {
                this.buildResultCard(item, index);
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 12, right: 12 })
          .scrollBar(BarState.Off)

          // 底部操作栏
          Row() {
            Button('全部确认')
              .layoutWeight(1)
              .height(44)
              .fontSize(15)
              .backgroundColor('#4a90d9')
              .borderRadius(22)
              .margin({ right: 8 })
              .onClick(() => { this.confirmAll(); })

            Button('重新识别')
              .layoutWeight(1)
              .height(44)
              .fontSize(15)
              .backgroundColor('#ffffff')
              .fontColor('#4a90d9')
              .border({ width: 1, color: '#4a90d9' })
              .borderRadius(22)
              .margin({ left: 8 })
              .onClick(() => {
                this.hasResult = false;
                this.items = [];
              })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 12, bottom: 20 })
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }

  /**
   * 结果卡片
   */
  @Builder
  buildResultCard(item: AiTaskItem, index: number) {
    Column() {
      // 象限标签 + 内容
      Row() {
        Text('' + item.quadrant)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .width(28)
          .height(28)
          .textAlign(TextAlign.Center)
          .backgroundColor(item.quadrant === 1 ? '#e74c3c' :
                           item.quadrant === 2 ? '#4a90d9' :
                           item.quadrant === 3 ? '#f39c12' : '#999')
          .borderRadius(14)

        Text(item.content)
          .fontSize(15)
          .fontColor('#333')
          .margin({ left: 10 })
          .layoutWeight(1)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')

      // 详情行
      Row() {
        Text('重要性:' + item.importance + '  紧急性:' + item.urgency)
          .fontSize(12)
          .fontColor('#999')

        Blank()

        Text(item.advice)
          .fontSize(12)
          .fontColor('#4a90d9')
          .fontWeight(FontWeight.Medium)

        if (item.deadline) {
          Text(' 📅' + item.deadline)
            .fontSize(11)
            .fontColor('#e74c3c')
            .margin({ left: 8 })
        }
      }
      .width('100%')
      .margin({ top: 8 })

      // 操作按钮
      Row() {
        if (item.confirmed) {
          Text('✓ 已确认')
            .fontSize(13)
            .fontColor('#27ae60')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('#e8f8f0')
            .borderRadius(14)
        } else {
          Button('确认')
            .height(32)
            .fontSize(12)
            .backgroundColor('#27ae60')
            .borderRadius(16)
            .enabled(!item.confirmed)
            .onClick(() => { this.confirmOne(index); })

          Button('修改')
            .height(32)
            .fontSize(12)
            .backgroundColor('#f0f0f0')
            .fontColor('#333')
            .borderRadius(16)
            .margin({ left: 8 })
            .onClick(() => {
              // 通过 AppStorage 传参到滑块页（绕过 router 序列化 bug）
              AppStorage.setOrCreate('slider_content', item.content || '');
              AppStorage.setOrCreate('slider_importance', item.importance || 50);
              AppStorage.setOrCreate('slider_urgency', item.urgency || 50);
              AppStorage.setOrCreate('slider_deadline', item.deadline ?? '');
              router.pushUrl({ url: 'pages/SliderCreatePage' });
            })
        }
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(item.confirmed ? '#fafffe' : '#ffffff')
    .borderRadius(10)
    .border({ width: 1, color: item.confirmed ? '#d4edda' : '#e8e8e8' })
    .margin({ bottom: 10 })
  }

  canParse(): boolean {
    return this.rawText.trim().length > 0;
  }

  /**
   * 调用 AI 解析
   */
  async doParse(): Promise<void> {
    this.loading = true;
    try {
      let reqData: Record<string, string> = { 'text': this.rawText.trim() };
      let data: object | null = await post('/api/task/ai-parse', reqData);
      if (data) {
        let resultList: AiTaskItem[] = data as AiTaskItem[];
        this.items = resultList;
        this.hasResult = true;
      }
    } finally {
      this.loading = false;
    }
  }

  /**
   * 逐条确认 → 创建任务
   */
  async confirmOne(index: number): Promise<void> {
    let item: AiTaskItem = this.items[index];
    let reqData: Record<string, Object> = {
      'content': item.content,
      'importance': item.importance,
      'urgency': item.urgency,
      'source': 2  // AI 识别
    };
    if (item.deadline) {
      reqData['deadline'] = item.deadline;
    }

    let data: object | null = await post('/api/task', reqData);
    if (data) {
      item.confirmed = true;
      promptAction.showToast({ message: '已创建: ' + item.content, duration: 1000 });
    }
  }

  /**
   * 全部确认
   */
  async confirmAll(): Promise<void> {
    let count: number = 0;
    for (let i = 0; i < this.items.length; i++) {
      if (!this.items[i].confirmed) {
        await this.confirmOne(i);
        count++;
      }
    }
    if (count > 0) {
      promptAction.showToast({ message: '全部确认完成，共' + count + '条', duration: 1500 });
      router.back();
    }
  }
}
