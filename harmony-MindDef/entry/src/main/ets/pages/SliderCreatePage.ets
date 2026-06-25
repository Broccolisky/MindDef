/**
 * 统一创建页面
 *
 * 用户可手动输入 + 拖动滑块，也可点击 🤖 打开 AI 识别面板，
 * 或点击"帮我判断"进入引导式问答
 */
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { post } from '../utils/HttpUtil';
import { calcQuadrant, getAdvice, getImportanceLabel, getUrgencyLabel, AiTaskItem } from '../model/TaskModel';
import { IconLabel } from '../components/IconLabel';

@Entry
@Component
struct SliderCreatePage {
  @State content: string = '';
  @State importance: number = 50;
  @State urgency: number = 50;
  @State deadline: string = '';
  @State loading: boolean = false;
  @State deadlineDate: Date = new Date(); // 日期选择器选中值（默认今天）

  // ── AI 识别面板（常驻）──
  @State aiRawText: string = '';
  @State aiLoading: boolean = false;
  @State aiItems: AiTaskItem[] = [];
  @State aiHasResult: boolean = false;

  // 不使用 get 访问器 —— ArkTS API 24 运行时可能不响应 @State 变化
  // 改为在各处直接调用 calcQuadrant / getAdvice / getImportanceLabel / getUrgencyLabel

  aboutToAppear(): void {
    // 通过 AppStorage 读取"微调"或 AI 解析页传入的参数
    // 默认值优先
    this.content = '';
    this.importance = 50;
    this.urgency = 50;

    let c: string | undefined = AppStorage.get('slider_content') as string | undefined;
    if (c !== undefined && c !== null) {
      this.content = c;
    }
    let imp: number | undefined = AppStorage.get('slider_importance') as number | undefined;
    if (imp !== undefined && imp !== null) {
      this.importance = imp;
    }
    let urg: number | undefined = AppStorage.get('slider_urgency') as number | undefined;
    if (urg !== undefined && urg !== null) {
      this.urgency = urg;
    }
    let dl: string | undefined = AppStorage.get('slider_deadline') as string | undefined;
    if (dl !== undefined && dl !== null && dl !== '') {
      this.deadline = dl;
    }
    // 清理 AppStorage，避免残留
    AppStorage.delete('slider_content');
    AppStorage.delete('slider_importance');
    AppStorage.delete('slider_urgency');
    AppStorage.delete('slider_deadline');
  }

  build() {
    Column() {
      // ── 标题栏 ──
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

      // ── 可滚动内容区 ──
      Scroll() {
        Column() {
          // ── 内容输入 ──
          TextArea({ placeholder: '输入事项内容...' })
            .width('100%')
            .height(120)
            .fontSize(16)
            .backgroundColor('#f8f8f8')
            .borderRadius(8)
            .padding(12)
            .margin({ left: 20, right: 20, top: 20 })
            .onChange((value: string) => {
              this.content = value;
            })

          // ── AI 识别面板（常驻）──
          Column() {
            if (!this.aiHasResult) {
              this.buildAiInputPhase();
            } else {
              this.buildAiResultPhase();
            }
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
          .backgroundColor('#fafafa')
          .borderRadius(8)
          .margin({ left: 20, right: 20, top: 12 })

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

              Text(getImportanceLabel(this.importance) || '--')
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

              Text(getUrgencyLabel(this.urgency) || '--')
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

          // ── 截止日期（日期选择器）──
          Column() {
            Row() {
              IconLabel({
                icon: $r('app.media.icon_calendar'),
                label: '截止日期',
                iconSize: 16,
                fontSize: 14,
                fontColor: '#666',
                iconColor: '#666',
                spacing: 4
              })

              Blank()

              if (this.deadline) {
                Text(this.deadline)
                  .fontSize(14)
                  .fontColor('#4a90d9')
                  .fontWeight(FontWeight.Medium)
                  .margin({ right: 8 })

                Image($r('app.media.icon_close'))
                  .width(16)
                  .height(16)
                  .fillColor('#999')
                  .onClick(() => {
                    this.deadline = '';
                  })
              } else {
                Row() {
                  Text('点击选择')
                    .fontSize(13)
                    .fontColor('#bbb')
                  Image($r('app.media.icon_forward'))
                    .width(12)
                    .height(12)
                    .fillColor('#bbb')
                    .margin({ left: 2 })
                }
              }
            }
            .width('100%')
            .height(44)
            .padding({ left: 14, right: 14 })
            .backgroundColor('#f8f8f8')
            .borderRadius(8)
            .margin({ top: 16 })
            .onClick(() => {
              DatePickerDialog.show({
                start: new Date(),
                end: new Date(new Date().getFullYear() + 3, 11, 31),
                selected: this.deadlineDate,
                lunar: false,
                onAccept: (value: DatePickerResult) => {
                  let m: number = value.month! + 1;
                  let month: string = m < 10 ? '0' + m : String(m);
                  let day: string = (value.day! < 10 ? '0' + value.day : String(value.day));
                  this.deadline = value.year + '-' + month + '-' + day;
                  // 更新选中日期，下次打开时保持
                  this.deadlineDate = new Date(value.year!, value.month!, value.day!);
                }
              });
            })
          }
          .width('100%')
          .padding({ left: 20, right: 20 })

          // ── 实时判定卡片 ──
          Row() {
            Column() {
              Text('象限 ' + calcQuadrant(this.importance, this.urgency) + ' · ' +
                   getAdvice(calcQuadrant(this.importance, this.urgency)))
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333')

              Text('建议：' + getAdvice(calcQuadrant(this.importance, this.urgency)))
                .fontSize(12)
                .fontColor('#999')
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            // 象限指示
            Text('' + calcQuadrant(this.importance, this.urgency))
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4a90d9')
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 14, bottom: 14 })
          .backgroundColor('#f0f7ff')
          .borderRadius(10)
          .margin({ left: 20, right: 20, top: 20 })

          // ── 引导判断入口 ──
          Row() {
            IconLabel({
              icon: $r('app.media.icon_help'),
              label: '不确定重要/紧急？试试帮我判断',
              iconSize: 14,
              fontSize: 12,
              iconColor: '#4a90d9',
              fontColor: '#4a90d9',
              spacing: 4
            })
            Image($r('app.media.icon_forward'))
              .width(10)
              .height(10)
              .fillColor('#4a90d9')
              .margin({ left: 2 })
          }
            .margin({ top: 8, left: 20, right: 20 })
            .onClick(() => {
              AppStorage.setOrCreate('guide_content', this.content || '');
              router.pushUrl({ url: 'pages/GuideCreatePage' });
            })

          Blank()
            .height(16)

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
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }

  // ═══════════════════════════════════════════
  //  AI 识别面板 —— @Builder 方法
  // ═══════════════════════════════════════════

  /**
   * AI 面板 —— 输入阶段
   */
  @Builder
  buildAiInputPhase() {
    Column() {
      // 标签 + 按钮同行
      Row() {
        IconLabel({
          icon: $r('app.media.icon_clipboard'),
          label: '粘贴内容，AI 自动识别',
          iconSize: 15,
          fontSize: 13,
          fontColor: '#666',
          iconColor: '#666',
          spacing: 4
        })
          .layoutWeight(1)

        Row() {
          if (this.aiLoading) {
            LoadingProgress().width(14).height(14).margin({ right: 4 })
            Text('分析中...')
              .fontSize(13).fontWeight(FontWeight.Medium).fontColor('#ffffff')
          } else {
            Image($r('app.media.icon_ai'))
              .width(16).height(16).fillColor('#ffffff').margin({ right: 4 })
            Text('AI 识别')
              .fontSize(13).fontWeight(FontWeight.Medium).fontColor('#ffffff')
          }
        }
          .height(34)
          .padding({ left: 14, right: 14 })
          .backgroundColor(this.aiRawText.trim().length > 0 && !this.aiLoading ? '#4a90d9' : '#ccc')
          .borderRadius(17)
          .hitTestBehavior(this.aiRawText.trim().length > 0 && !this.aiLoading ? HitTestMode.Default : HitTestMode.None)
          .onClick(() => { this.doAiParse(); })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 12, bottom: 8 })

      TextArea({ placeholder: '将聊天记录、会议纪要等内容粘贴到这里...' })
        .width('100%')
        .height(100)
        .fontSize(14)
        .backgroundColor('#ffffff')
        .borderRadius(8)
        .padding(10)
        .onChange((value: string) => {
          this.aiRawText = value;
        })

      if (this.aiLoading) {
        Row() {
          LoadingProgress()
            .width(24)
            .height(24)

          Text('AI 正在分析中，请稍候...')
            .fontSize(12)
            .fontColor('#999')
            .margin({ left: 8 })
        }
        .width('100%')
        .margin({ top: 10, bottom: 8 })
      }
    }
    .width('100%')
  }

  /**
   * AI 面板 —— 结果展示阶段
   */
  @Builder
  buildAiResultPhase() {
    Column() {
      Row() {
        IconLabel({
          icon: $r('app.media.icon_ai'),
          label: '识别结果：',
          iconSize: 16,
          fontSize: 14,
          fontWeight: FontWeight.Bold,
          fontColor: '#333',
          iconColor: '#4a90d9',
          spacing: 4
        })

        Blank()

        Text(this.aiItems.length + ' 条')
          .fontSize(11)
          .fontColor('#999')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor('#f0f0f0')
          .borderRadius(8)
      }
      .width('100%')
      .margin({ top: 12, bottom: 8 })

      // 结果卡片列表
      List() {
        ForEach(this.aiItems, (item: AiTaskItem, index: number) => {
          ListItem() {
            this.buildAiResultCard(item, index);
          }
        })
      }
      .width('100%')
      .constraintSize({ maxHeight: 300 })
      .scrollBar(BarState.Off)

      // 底部操作栏
      Row() {
        Button('全部确认')
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .backgroundColor('#4a90d9')
          .borderRadius(20)
          .margin({ right: 6 })
          .onClick(() => { this.confirmAllAi(); })

        Button('重新识别')
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .backgroundColor('#ffffff')
          .fontColor('#4a90d9')
          .border({ width: 1, color: '#4a90d9' })
          .borderRadius(20)
          .margin({ left: 6 })
          .onClick(() => {
            this.aiHasResult = false;
            this.aiItems = [];
          })
      }
      .width('100%')
      .margin({ top: 12, bottom: 12 })
    }
    .width('100%')
  }

  /**
   * AI 结果卡片
   */
  @Builder
  buildAiResultCard(item: AiTaskItem, index: number) {
    Column() {
      // 象限标签 + 内容
      Row() {
        Text('' + item.quadrant)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .width(26)
          .height(26)
          .textAlign(TextAlign.Center)
          .backgroundColor(item.quadrant === 1 ? '#e74c3c' :
                           item.quadrant === 2 ? '#4a90d9' :
                           item.quadrant === 3 ? '#f39c12' : '#999')
          .borderRadius(13)

        Text(item.content)
          .fontSize(14)
          .fontColor('#333')
          .margin({ left: 8 })
          .layoutWeight(1)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')

      // 详情行
      Row() {
        Text('重要性:' + item.importance + '  紧急性:' + item.urgency)
          .fontSize(11)
          .fontColor('#999')

        Blank()

        Text(item.advice)
          .fontSize(11)
          .fontColor('#4a90d9')
          .fontWeight(FontWeight.Medium)

        if (item.deadline) {
          Row() {
            Image($r('app.media.icon_calendar'))
              .width(10).height(10).fillColor('#e74c3c').margin({ right: 2 })
            Text(item.deadline!)
              .fontSize(10).fontColor('#e74c3c')
          }
            .margin({ left: 6 })
        }
      }
      .width('100%')
      .margin({ top: 6 })

      // 操作按钮
      Row() {
        if (item.confirmed) {
          Text('✓ 已确认')
            .fontSize(12)
            .fontColor('#27ae60')
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor('#e8f8f0')
            .borderRadius(12)
        } else {
          Button('确认')
            .height(30)
            .fontSize(11)
            .backgroundColor('#27ae60')
            .borderRadius(14)
            .onClick(() => { this.confirmOneAi(index); })

          Button('填入表单')
            .height(30)
            .fontSize(11)
            .backgroundColor('#4a90d9')
            .borderRadius(14)
            .margin({ left: 6 })
            .onClick(() => {
              // 将 AI 结果填入主表单
              this.content = item.content;
              this.importance = item.importance;
              this.urgency = item.urgency;
              this.deadline = item.deadline ?? '';
              this.deadlineDate = item.deadline ? new Date(item.deadline) : new Date();
              // 重置 AI 面板
              this.aiHasResult = false;
              this.aiItems = [];
              this.aiRawText = '';
            })
        }
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(item.confirmed ? '#fafffe' : '#ffffff')
    .borderRadius(8)
    .border({ width: 1, color: item.confirmed ? '#d4edda' : '#e8e8e8' })
    .margin({ bottom: 8 })
  }

  // ═══════════════════════════════════════════
  //  方法
  // ═══════════════════════════════════════════

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

  /**
   * 调用 AI 解析
   */
  async doAiParse(): Promise<void> {
    this.aiLoading = true;
    try {
      let reqData: Record<string, string> = { 'text': this.aiRawText.trim() };
      let data: object | null = await post('/api/task/ai-parse', reqData);
      if (data) {
        // 确保后端返回数组（容错非数组响应）
        let rawList: Object[] = Array.isArray(data) ? (data as Object[]) : [data];
        let resultList: AiTaskItem[] = rawList as AiTaskItem[];
        this.aiItems = resultList;
        this.aiHasResult = true;
      }
    } finally {
      this.aiLoading = false;
    }
  }

  /**
   * 确认单条 AI 结果 → 直接创建
   */
  async confirmOneAi(index: number): Promise<void> {
    let item: AiTaskItem = this.aiItems[index];
    let reqData: Record<string, Object> = {
      'content': item.content,
      'importance': item.importance,
      'urgency': item.urgency,
      'source': 2
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
  async confirmAllAi(): Promise<void> {
    let count: number = 0;
    for (let i = 0; i < this.aiItems.length; i++) {
      if (!this.aiItems[i].confirmed) {
        await this.confirmOneAi(i);
        count++;
      }
    }
    if (count > 0) {
      promptAction.showToast({ message: '全部确认完成，共' + count + '条', duration: 1500 });
      router.back();
    }
  }
}
