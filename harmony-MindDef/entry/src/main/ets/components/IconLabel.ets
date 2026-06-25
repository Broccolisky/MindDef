/**
 * 图标 + 文字组合组件
 *
 * 用于替代 emoji，展示图标库中的矢量图标
 */
@Component
export struct IconLabel {
  @Prop icon: Resource = $r('app.media.icon_check');
  @Prop label: string = '';
  @Prop iconSize: number = 16;
  @Prop fontSize: number = 14;
  @Prop iconColor: string = '#4a90d9';
  @Prop fontColor: string = '#333';
  @Prop fontWeight: number = FontWeight.Normal;
  @Prop spacing: number = 4;

  build() {
    Row() {
      Image(this.icon)
        .width(this.iconSize)
        .height(this.iconSize)
        .fillColor(this.iconColor)
        .margin({ right: this.spacing })

      if (this.label) {
        Text(this.label)
          .fontSize(this.fontSize)
          .fontColor(this.fontColor)
          .fontWeight(this.fontWeight)
      }
    }
    .alignItems(VerticalAlign.Center)
  }
}
