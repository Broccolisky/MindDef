/**
 * 个人中心页面 — 从标题栏头像进入，管理昵称/密码/退出
 */
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { get, put } from '../utils/HttpUtil';
import { clearLoginInfo, getNickname, saveLoginInfo, getToken, getUserId } from '../utils/TokenUtil';
import { IconLabel } from '../components/IconLabel';

@Entry
@Component
export struct ProfilePage {
  @State nickname: string = '';
  @State loaded: boolean = false;
  // 修改昵称
  @State isEditingNickname: boolean = false;
  @State newNickname: string = '';
  // 修改密码
  @State isEditingPwd: boolean = false;
  @State oldPwd: string = '';
  @State newPwd: string = '';

  aboutToAppear(): void {
    this.loadProfile();
  }

  async loadProfile(): Promise<void> {
    let data: object | null = await get('/api/user/profile');
    if (data) {
      this.nickname = (data as Record<string, string>)['nickname'] || '';
      this.loaded = true;
    }
  }

  async doUpdateNickname(): Promise<void> {
    if (!this.newNickname.trim()) {
      promptAction.showToast({ message: '昵称不能为空', duration: 1500 });
      return;
    }
    let nickData: Record<string, string> = { 'nickname': this.newNickname.trim() };
    let data: object | null = await put('/api/user/nickname', nickData);
    if (data) {
      this.nickname = this.newNickname.trim();
      this.isEditingNickname = false;
      let token: string = await getToken();
      let userId: number = await getUserId();
      await saveLoginInfo(token, userId, this.nickname);
      promptAction.showToast({ message: '昵称修改成功', duration: 1000 });
    }
  }

  async doUpdatePassword(): Promise<void> {
    if (!this.oldPwd || !this.newPwd) {
      promptAction.showToast({ message: '密码不能为空', duration: 1500 });
      return;
    }
    if (this.newPwd.length < 6) {
      promptAction.showToast({ message: '新密码须6-20位', duration: 1500 });
      return;
    }
    let pwdData: Record<string, string> = {
      'oldPassword': this.oldPwd,
      'newPassword': this.newPwd
    };
    let data: object | null = await put('/api/user/password', pwdData);
    if (data) {
      this.isEditingPwd = false;
      this.oldPwd = '';
      this.newPwd = '';
      promptAction.showToast({ message: '密码修改成功', duration: 1000 });
    }
  }

  async doLogout(): Promise<void> {
    await clearLoginInfo();
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  @Builder
  buildSectionHeader(title: string) {
    Text(title)
      .fontSize(13)
      .fontColor('#999')
      .fontWeight(FontWeight.Medium)
      .width('100%')
      .margin({ top: 28, bottom: 8 })
  }

  build() {
    Column() {
      // ── 顶部导航栏 ──
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

        Text('个人中心')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1a1a1a')

        Blank()

        // 对称占位，保证标题居中
        Row()
          .width(60)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Divider()

      // ── 主体内容 ──
      Scroll() {
        Column() {
          if (!this.loaded) {
            LoadingProgress().width(36).height(36).margin({ top: 80 })
          } else {
            // ── 头像 + 昵称 ──
            Image($r('app.media.icon_user'))
              .width(72)
              .height(72)
              .fillColor('#4a90d9')
              .margin({ top: 32 })

            Text(this.nickname)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1a1a1a')
              .margin({ top: 12 })

            // ── 修改昵称 ──
            this.buildSectionHeader('修改昵称')

            if (!this.isEditingNickname) {
              Row() {
                Text('当前昵称: ' + this.nickname)
                  .fontSize(15)
                  .fontColor('#333')
                  .layoutWeight(1)

                Image($r('app.media.icon_forward'))
                  .width(14)
                  .height(14)
                  .fillColor('#999')
              }
              .width('100%')
              .padding(14)
              .backgroundColor('#ffffff')
              .borderRadius(8)
              .onClick(() => {
                this.newNickname = this.nickname;
                this.isEditingNickname = true;
              })
            } else {
              Column() {
                TextInput({ text: this.newNickname, placeholder: '输入新昵称' })
                  .width('100%')
                  .height(44)
                  .fontSize(15)
                  .backgroundColor('#f8f8f8')
                  .borderRadius(8)
                  .onChange((v: string) => { this.newNickname = v; })

                Row() {
                  Button('取消')
                    .fontSize(14)
                    .backgroundColor('#f0f0f0')
                    .fontColor('#333')
                    .layoutWeight(1)
                    .margin({ right: 8 })
                    .onClick(() => { this.isEditingNickname = false; })

                  Button('保存')
                    .fontSize(14)
                    .backgroundColor('#4a90d9')
                    .layoutWeight(1)
                    .margin({ left: 8 })
                    .onClick(() => { this.doUpdateNickname(); })
                }
                .width('100%')
                .margin({ top: 10 })
              }
              .width('100%')
              .padding(14)
              .backgroundColor('#ffffff')
              .borderRadius(8)
            }

            // ── 修改密码 ──
            this.buildSectionHeader('修改密码')

            if (!this.isEditingPwd) {
              Row() {
                Text('点击修改登录密码')
                  .fontSize(15)
                  .fontColor('#999')
                  .layoutWeight(1)

                Image($r('app.media.icon_forward'))
                  .width(14)
                  .height(14)
                  .fillColor('#999')
              }
              .width('100%')
              .padding(14)
              .backgroundColor('#ffffff')
              .borderRadius(8)
              .onClick(() => { this.isEditingPwd = true; })
            } else {
              Column() {
                TextInput({ text: this.oldPwd, placeholder: '原密码' })
                  .width('100%')
                  .height(44)
                  .fontSize(15)
                  .backgroundColor('#f8f8f8')
                  .borderRadius(8)
                  .type(InputType.Password)
                  .onChange((v: string) => { this.oldPwd = v; })

                TextInput({ text: this.newPwd, placeholder: '新密码 (6-20位)' })
                  .width('100%')
                  .height(44)
                  .fontSize(15)
                  .backgroundColor('#f8f8f8')
                  .borderRadius(8)
                  .type(InputType.Password)
                  .margin({ top: 8 })
                  .onChange((v: string) => { this.newPwd = v; })

                Row() {
                  Button('取消')
                    .fontSize(14)
                    .backgroundColor('#f0f0f0')
                    .fontColor('#333')
                    .layoutWeight(1)
                    .margin({ right: 8 })
                    .onClick(() => {
                      this.isEditingPwd = false;
                      this.oldPwd = '';
                      this.newPwd = '';
                    })

                  Button('确认修改')
                    .fontSize(14)
                    .backgroundColor('#e74c3c')
                    .layoutWeight(1)
                    .margin({ left: 8 })
                    .onClick(() => { this.doUpdatePassword(); })
                }
                .width('100%')
                .margin({ top: 10 })
              }
              .width('100%')
              .padding(14)
              .backgroundColor('#ffffff')
              .borderRadius(8)
            }

            // ── 退出登录 ──
            Button('退出登录')
              .width('70%')
              .height(44)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .backgroundColor('#ffffff')
              .fontColor('#e74c3c')
              .border({ width: 1, color: '#e74c3c' })
              .borderRadius(22)
              .margin({ top: 36, bottom: 40 })
              .onClick(() => { this.doLogout(); })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ left: 20, right: 20 })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#f8f8f8')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }
}
