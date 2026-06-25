/**
 * 引导创建页面 —— 2 题问答定象限
 *
 * Q1: "这件事今天不做会怎样？" → 紧急性
 * Q2: "这件事和你的长期目标有关吗？" → 重要性
 */
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { post } from '../utils/HttpUtil';
import { calcQuadrant, getAdvice } from '../model/TaskModel';
import { IconLabel } from '../components/IconLabel';

@Entry
@Component
struct GuideCreatePage {
  @State content: string = '';
  @State step: number = 1;          // 1:填内容 2:Q1 3:Q2 4:确认
  @State urgency: number = 50;
  @State importance: number = 50;
  @State loading: boolean = false;   // 防重复提交

  // 不使用 get 访问器——@Builder 方法无法访问 class getter（ArkTS API 24 限制）
  // 改为在各 @Builder 内部直接调用 calcQuadrant / getAdvice

  aboutToAppear(): void {
    // 从统一创建页跳转时预填内容
    let gc: string | undefined = AppStorage.get('guide_content') as string | undefined;
    if (gc !== undefined && gc !== null && gc !== '') {
      this.content = gc;
      AppStorage.delete('guide_content');
    }
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

        Text('帮我判断')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)

        Blank()

        Text('    ')
          .fontSize(14)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Divider()

      // ── 进度指示器 ──
      Row() {
        ForEach(['内容', '紧急性', '重要性', '确认'], (label: string, index: number) => {
          Row() {
            Text('' + (index + 1))
              .fontSize(12)
              .fontColor(this.step > index + 1 ? '#fff' : (this.step === index + 1 ? '#fff' : '#999'))
              .width(24)
              .height(24)
              .textAlign(TextAlign.Center)
              .backgroundColor(this.step >= index + 1 ? '#4a90d9' : '#e0e0e0')
              .borderRadius(12)

            Text(label)
              .fontSize(11)
              .fontColor(this.step >= index + 1 ? '#333' : '#ccc')
              .margin({ left: 4 })
          }
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .padding({ top: 20, bottom: 16 })

      // ── 步骤内容 ──
      if (this.step === 1) {
        this.buildStep1();
      } else if (this.step === 2) {
        this.buildStep2();
      } else if (this.step === 3) {
        this.buildStep3();
      } else {
        this.buildStep4();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }

  // ── 第1步：输入内容 ──
  @Builder
  buildStep1() {
    Column() {
      Text('你要做什么事？')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 24 })

      TextInput({ placeholder: '输入事项内容...' })
        .width('100%')
        .height(48)
        .fontSize(16)
        .backgroundColor('#f8f8f8')
        .borderRadius(8)
        .margin({ left: 32, right: 32 })
        .onChange((value: string) => {
          this.content = value;
        })

      Blank()

      Button('下一步')
        .width('80%')
        .height(48)
        .fontSize(16)
        .backgroundColor(this.content.trim() ? '#4a90d9' : '#ccc')
        .borderRadius(24)
        .margin({ bottom: 40 })
        .enabled(this.content.trim() !== '')
        .onClick(() => { this.step = 2; })
    }
    .width('100%')
    .layoutWeight(1)
  }

  // ── 第2步：判断紧急性 ──
  @Builder
  buildStep2() {
    Column() {
      Text('这件事今天不做会怎样？')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 32 })

      Column() {
        this.buildOption('A. 会有严重后果', 80, () => { this.urgency = 80; this.step = 3; });
        this.buildOption('B. 有点麻烦但能补救', 50, () => { this.urgency = 50; this.step = 3; });
        this.buildOption('C. 没什么影响', 20, () => { this.urgency = 20; this.step = 3; });
      }
      .width('100%')
      .padding({ left: 32, right: 32 })

      Blank()
    }
    .width('100%')
    .layoutWeight(1)
  }

  // ── 第3步：判断重要性 ──
  @Builder
  buildStep3() {
    Column() {
      Text('这件事和你的长期目标有关吗？')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 32 })

      Column() {
        this.buildOption('A. 直接相关', 80, () => { this.importance = 80; this.step = 4; });
        this.buildOption('B. 间接有帮助', 50, () => { this.importance = 50; this.step = 4; });
        this.buildOption('C. 没什么关系', 20, () => { this.importance = 20; this.step = 4; });
      }
      .width('100%')
      .padding({ left: 32, right: 32 })

      Blank()
    }
    .width('100%')
    .layoutWeight(1)
  }

  // ── 第4步：确认 ──
  @Builder
  buildStep4() {
    Column() {
      Text('判定结果')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 24 })

      // 内容展示
      Text((this.content && this.content !== 'undefined' && this.content !== 'null') ? this.content : '（未填写）')
        .fontSize(16)
        .fontColor('#333')
        .margin({ bottom: 16 })

      // 判定卡片（直接內联计算——@Builder 无法访问 class getter，也不能声明 let）
      Column() {
        Text('象限 ' + calcQuadrant(this.importance, this.urgency)
          + ' · ' + getAdvice(calcQuadrant(this.importance, this.urgency)))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4a90d9')

        Text('建议：' + getAdvice(calcQuadrant(this.importance, this.urgency)))
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 8 })
      }
      .width('80%')
      .padding({ top: 24, bottom: 24 })
      .backgroundColor('#f0f7ff')
      .borderRadius(12)
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 16 })

      Blank()

      Button('确认放入象限')
        .width('80%')
        .height(48)
        .fontSize(16)
        .backgroundColor('#4a90d9')
        .borderRadius(24)
        .margin({ bottom: 16 })
        .enabled(!this.loading)
        .onClick(() => { this.doCreate(); })

      Button('微调')
        .width('80%')
        .height(44)
        .fontSize(14)
        .backgroundColor('#ffffff')
        .fontColor('#4a90d9')
        .border({ width: 1, color: '#4a90d9' })
        .borderRadius(24)
        .margin({ bottom: 40 })
        .onClick(() => {
          // 跳转到滑块页微调（带预填内容）
          // 通过 AppStorage 传参到滑块页（绕过 router 序列化 bug）
          AppStorage.setOrCreate('slider_content', this.content || '');
          AppStorage.setOrCreate('slider_importance', this.importance || 50);
          AppStorage.setOrCreate('slider_urgency', this.urgency || 50);
          router.pushUrl({ url: 'pages/SliderCreatePage' });
        })
    }
    .width('100%')
    .layoutWeight(1)
  }

  /**
   * 选项卡片
   */
  @Builder
  buildOption(label: string, value: number, callback: () => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#333')
        .layoutWeight(1)

      Image($r('app.media.icon_forward'))
        .width(16)
        .height(16)
        .fillColor('#ccc')
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#f8f8f8')
    .borderRadius(10)
    .margin({ bottom: 12 })
    .onClick(callback)
  }

  /**
   * 提交创建
   */
  async doCreate(): Promise<void> {
    if (this.loading) return;
    this.loading = true;
    try {
      let reqData: Record<string, Object> = {
        'content': this.content.trim(),
        'importance': this.importance,
        'urgency': this.urgency,
        'source': 3   // 引导创建
      };

      let data: object | null = await post('/api/task', reqData);
      if (data) {
        promptAction.showToast({ message: '创建成功', duration: 1000 });
        router.back();
        // 回到首页后会触发 onPageShow 刷新
      }
    } finally {
      this.loading = false;
    }
  }
}
