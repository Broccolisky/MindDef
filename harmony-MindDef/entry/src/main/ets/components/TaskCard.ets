/**
 * 任务卡片组件
 *
 * 展示任务内容、日期信息。通过卡片右下角"⋮"按钮唤起操作菜单。
 * 长按拖拽删除由父组件 draggable 接管。
 */
import { TaskModel } from '../model/TaskModel';
import { IconLabel } from '../components/IconLabel';

@Component
export struct TaskCard {
  @Prop task: TaskModel;
  onTap?: (task: TaskModel) => void;
  onMenuTap?: (task: TaskModel) => void;

  build() {
    Column() {
      Text(this.task.content || '（无内容）')
        .fontSize(14)
        .fontColor('#333')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Row() {
        if (this.task.scheduledDate) {
          Row() {
            Image($r('app.media.icon_calendar'))
              .width(11)
              .height(11)
              .fillColor('#4a90d9')
              .margin({ right: 2 })
            Text(this.task.scheduledDate)
              .fontSize(11)
              .fontColor('#4a90d9')
          }
        }
        if (this.task.deadline) {
          Row() {
            Image($r('app.media.icon_calendar'))
              .width(11)
              .height(11)
              .fillColor('#e74c3c')
              .margin({ right: 2 })
            Text(this.task.deadline)
              .fontSize(11)
              .fontColor('#e74c3c')
          }
        }

        Blank()

        if (this.task.source === 2) {
          Row() {
            Image($r('app.media.icon_ai'))
              .width(12)
              .height(12)
              .fillColor('#666')
              .margin({ right: 2 })
            Text('AI')
              .fontSize(10)
              .fontColor('#666')
          }
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor('#f0f0f0')
          .borderRadius(4)
        }

        if (this.onMenuTap) {
          Column() {
            Text('⋮')
              .fontSize(20)
              .fontColor('#aaa')
          }
          .padding({ left: 10, right: 4 })
          .hitTestBehavior(HitTestMode.Block)
          .onClick(() => {
            this.onMenuTap!(this.task);
          })
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
  }
}
