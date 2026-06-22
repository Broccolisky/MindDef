/**
 * 决策统计页面
 */
import { get } from '../utils/HttpUtil';

@Entry
@Component
export struct StatsPage {
  @State total: number = 0;
  @State completed: number = 0;
  @State abandoned: number = 0;
  @State thisWeek: number = 0;
  @State thisMonth: number = 0;
  @State quad1: number = 0;
  @State quad2: number = 0;
  @State quad3: number = 0;
  @State quad4: number = 0;
  @State loaded: boolean = false;

  onPageShow(): void {
    this.loadStats();
  }

  async loadStats(): Promise<void> {
    let data: object | null = await get('/api/stats/overview');
    if (data) {
      let s: Record<string, Object> = data as Record<string, Object>;
      this.total = s['total'] as number;
      this.completed = s['completed'] as number;
      this.abandoned = s['abandoned'] as number;
      this.thisWeek = s['thisWeek'] as number;
      this.thisMonth = s['thisMonth'] as number;
      let qd: Record<string, number> = s['quadrantDistribution'] as Record<string, number>;
      if (qd) {
        this.quad1 = qd['1'] || 0;
        this.quad2 = qd['2'] || 0;
        this.quad3 = qd['3'] || 0;
        this.quad4 = qd['4'] || 0;
      }
      this.loaded = true;
    }
  }

  get distTotal(): number {
    return this.quad1 + this.quad2 + this.quad3 + this.quad4;
  }

  pct(n: number): string {
    if (this.distTotal === 0) return '0%';
    return Math.round(n / this.distTotal * 100) + '%';
  }

  build() {
    Column() {
      Text('📊 我的决策统计')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 })

      if (!this.loaded) {
        LoadingProgress().width(36).height(36).margin({ top: 60 })
      } else {
        // 概览卡片
        Row() {
          this.buildStatCard('累计事项', '' + this.total, '#4a90d9')
          this.buildStatCard('已完成', '' + this.completed, '#27ae60')
          this.buildStatCard('已放弃', '' + this.abandoned, '#999')
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({ top: 24 })

        // 象限分布
        Column() {
          Text('象限分布')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .width('90%')
            .margin({ top: 28, bottom: 12 })

          this.buildQuadrantBar('① 立刻做', this.quad1, '#e74c3c')
          this.buildQuadrantBar('② 计划做', this.quad2, '#4a90d9')
          this.buildQuadrantBar('③ 简化做', this.quad3, '#f39c12')
          this.buildQuadrantBar('④ 不做',   this.quad4, '#999')
        }
        .width('90%')

        // 时间维度
        Row() {
          this.buildStatCard('本周完成', '' + this.thisWeek, '#f39c12')
          this.buildStatCard('本月完成', '' + this.thisMonth, '#9b59b6')
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({ top: 24 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8f8f8')
  }

  @Builder
  buildStatCard(label: string, value: string, color: string) {
    Column() {
      Text(value)
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(12)
        .fontColor('#999')
        .margin({ top: 4 })
    }
    .width('28%')
    .padding({ top: 16, bottom: 16 })
    .backgroundColor('#ffffff')
    .borderRadius(10)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildQuadrantBar(label: string, count: number, color: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#333')
        .width(80)

      Progress({
        value: this.distTotal > 0 ? count / this.distTotal * 100 : 0,
        total: 100,
        type: ProgressType.Linear
      })
        .layoutWeight(1)
        .height(8)
        .color(color)
        .backgroundColor('#e8e8e8')

      Text(this.pct(count))
        .fontSize(13)
        .fontColor('#666')
        .width(40)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
  }
}
