/**
 * 任务卡片组件
 *
 * 展示任务内容、日期信息，支持长按菜单和滑动删除（④象限）
 */
import { TaskModel } from '../model/TaskModel';

@Component
export struct TaskCard {
  @Prop task: TaskModel;
  onLongPress?: (task: TaskModel) => void;
  onTap?: (task: TaskModel) => void;

  build() {
    Column() {
      // 内容
      Text(this.task.content)
        .fontSize(14)
        .fontColor('#333')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // 底部信息行
      Row() {
        // 截止日期
        if (this.task.deadline) {
          Text('📅 ' + this.task.deadline)
            .fontSize(11)
            .fontColor('#e74c3c')
        }

        Blank()

        // 来源标签
        if (this.task.source === 2) {
          Text('🤖 AI')
            .fontSize(10)
            .fontColor('#666')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor('#f0f0f0')
            .borderRadius(4)
        }
      }
      .width('100%')
      .margin({ top: 4 })
    }
    .width('100%')
    .padding({ top: 8, bottom: 8, left: 10, right: 10 })
    .backgroundColor('#ffffff')
    .borderRadius(8)
    .margin({ bottom: 6 })
    .onClick(() => {
      if (this.onTap) {
        this.onTap(this.task);
      }
    })
    .gesture(
      LongPressGesture()
        .onAction(() => {
          if (this.onLongPress) {
            this.onLongPress(this.task);
          }
        })
    )
  }
}
