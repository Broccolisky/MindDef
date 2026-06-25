/**
 * AI 助手页 — 聊天界面
 *
 * 作为子组件嵌入 Index.ets 的第三个 TabContent，
 * 通过 POST /api/ai/chat 与后端对话，AI 能根据用户任务数据提供个性化建议
 */
import { post } from '../utils/HttpUtil';

/** 聊天消息 */
interface ChatMessage {
  role: 'user' | 'ai';
  content: string;
}

@Component
export struct AiChatPage {
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State loading: boolean = false;
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    // 欢迎消息（仅首次）
    if (this.messages.length === 0) {
      let welcome: ChatMessage = {
        role: 'ai',
        content: '你好！我是 MindDef 助手\n\n我可以帮你分析任务分布、建议优先级、规划日程。随便问我吧，比如：\n- "我今天应该先做什么？"\n- "帮我看看任务安排是否合理"\n- "有什么任务该调整优先级？"'
      };
      this.messages.push(welcome);
    }
  }

  build() {
    Column() {
      // ── 标题栏 ──
      Row() {
        Image($r('app.media.icon_ai'))
          .width(22)
          .height(22)
          .fillColor('#4a90d9')
          .margin({ right: 8 })

        Text('AI 助手')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })
      .backgroundColor('#ffffff')

      Divider()

      // ── 消息列表 ──
      Scroll(this.scroller) {
        Column() {
          ForEach(this.messages, (msg: ChatMessage, index: number) => {
            Column() {
              this.buildMessageBubble(msg, index);
            }
          }, (msg: ChatMessage, index: number) => index.toString())

          // 加载动画
          if (this.loading) {
            Row() {
              Image($r('app.media.icon_ai'))
                .width(20)
                .height(20)
                .fillColor('#4a90d9')
                .margin({ right: 8 })

              LoadingProgress()
                .width(16)
                .height(16)

              Text('思考中...')
                .fontSize(13)
                .fontColor('#999')
                .margin({ left: 6 })
            }
            .padding({ left: 16, top: 12, bottom: 4 })
            .width('100%')
          }

          // 底部留白
          Blank().height(12)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .backgroundColor('#f5f5f5')
      .padding({ left: 12, right: 12, top: 8 })
      .onTouch(() => {
        // 触摸时不做特殊处理，保持滚动位置由用户控制
      })

      Divider()

      // ── 底部输入栏 ──
      Row() {
        TextInput({ text: this.inputText, placeholder: '输入消息…' })
          .layoutWeight(1)
          .height(42)
          .fontSize(15)
          .backgroundColor('#f0f0f0')
          .borderRadius(21)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.inputText = value;
          })
          .onSubmit(() => {
            this.sendMessage();
          })

        Button(this.loading ? '…' : '发送')
          .height(40)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.canSend() ? '#4a90d9' : '#ccc')
          .fontColor('#ffffff')
          .borderRadius(20)
          .margin({ left: 8 })
          .enabled(this.canSend() && !this.loading)
          .onClick(() => {
            this.sendMessage();
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor('#ffffff')
    }
    .width('100%')
    .height('100%')
  }

  // ═══════════════════════════════════════════
  //  消息气泡
  // ═══════════════════════════════════════════

  @Builder
  buildMessageBubble(msg: ChatMessage, index: number) {
    Row() {
      if (msg.role === 'user') {
        // 用户消息：右对齐
        Blank()
        Column() {
          Text(msg.content)
            .fontSize(15)
            .fontColor('#ffffff')
            .padding({ left: 14, right: 14, top: 10, bottom: 10 })
            .backgroundColor('#4a90d9')
            .borderRadius({ topLeft: 16, topRight: 16, bottomLeft: 16, bottomRight: 4 })
            .textAlign(TextAlign.Start)
        }
        .constraintSize({ maxWidth: '80%' })
        .alignItems(HorizontalAlign.End)
        .margin({ top: 8 })

        Image($r('app.media.icon_user'))
          .width(28)
          .height(28)
          .fillColor('#4a90d9')
          .margin({ left: 6 })
      } else {
        // AI 消息：左对齐
        Image($r('app.media.icon_ai'))
          .width(28)
          .height(28)
          .fillColor('#4a90d9')
          .margin({ right: 6 })

        Column() {
          Text(msg.content)
            .fontSize(15)
            .fontColor('#333')
            .padding({ left: 14, right: 14, top: 10, bottom: 10 })
            .backgroundColor('#ffffff')
            .borderRadius({ topLeft: 16, topRight: 16, bottomLeft: 4, bottomRight: 16 })
            .textAlign(TextAlign.Start)
        }
        .constraintSize({ maxWidth: '80%' })
        .alignItems(HorizontalAlign.Start)
        .margin({ top: 8 })

        Blank()
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  // ═══════════════════════════════════════════
  //  发送消息
  // ═══════════════════════════════════════════

  canSend(): boolean {
    return this.inputText.trim().length > 0;
  }

  async sendMessage(): Promise<void> {
    let text: string = this.inputText.trim();
    if (text === '' || this.loading) return;

    // 1. 添加用户消息
    let userMsg: ChatMessage = { role: 'user', content: text };
    this.messages.push(userMsg);
    this.inputText = '';

    // 2. 滚动到底
    this.scrollToBottom();

    // 3. 调 AI 接口
    this.loading = true;
    try {
      let reqData: Record<string, Object> = { 'question': text };
      let data: object | null = await post('/api/ai/chat', reqData);
      if (data) {
        let resp: Record<string, Object> = data as Record<string, Object>;
        let answer: string = (resp['answer'] as string) || '抱歉，没能获取到回复。';
        let aiMsg: ChatMessage = { role: 'ai', content: answer };
        this.messages.push(aiMsg);
      } else {
        let errMsg: ChatMessage = { role: 'ai', content: '网络请求失败，请检查后端是否启动。' };
        this.messages.push(errMsg);
      }
    } catch (e) {
      let failMsg: ChatMessage = { role: 'ai', content: '发送失败，请稍后重试。' };
      this.messages.push(failMsg);
    } finally {
      this.loading = false;
      this.scrollToBottom();
    }
  }

  scrollToBottom(): void {
    // 延迟一帧，确保消息已渲染
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 50);
  }
}
