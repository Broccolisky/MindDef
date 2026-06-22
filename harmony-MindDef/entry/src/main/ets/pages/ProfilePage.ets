/**
 * 个人中心页面
 *
 * 显示昵称、修改昵称、修改密码、退出登录
 */
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { get, put } from '../utils/HttpUtil';
import { clearLoginInfo, getNickname } from '../utils/TokenUtil';

@Entry
@Component
export struct ProfilePage {
  @State nickname: string = '';
  @State showNicknameEdit: boolean = false;
  @State newNickname: string = '';
  @State showPwdEdit: boolean = false;
  @State oldPwd: string = '';
  @State newPwd: string = '';
  @State loaded: boolean = false;

  onPageShow(): void {
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
      this.showNicknameEdit = false;
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
      this.showPwdEdit = false;
      this.oldPwd = '';
      this.newPwd = '';
      promptAction.showToast({ message: '密码修改成功', duration: 1000 });
    }
  }

  async doLogout(): Promise<void> {
    await clearLoginInfo();
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  build() {
    Column() {
      Text('👤 个人中心')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 24 })

      if (!this.loaded) {
        LoadingProgress().width(36).height(36).margin({ top: 40 })
      } else {
        // 头像占位
        Text('🧑‍💻')
          .fontSize(64)
          .margin({ bottom: 12 })

        // 昵称
        Row() {
          Text('昵称: ' + this.nickname)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)

          Text('  ✎')
            .fontSize(14)
            .fontColor('#4a90d9')
            .onClick(() => {
              this.newNickname = this.nickname;
              this.showNicknameEdit = true;
            })
        }
        .margin({ bottom: 32 })

        // 修改昵称弹窗
        if (this.showNicknameEdit) {
          Column() {
            TextInput({ placeholder: '新昵称' })
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
                .onClick(() => { this.showNicknameEdit = false; })

              Button('保存')
                .fontSize(14)
                .backgroundColor('#4a90d9')
                .layoutWeight(1)
                .margin({ left: 8 })
                .onClick(() => { this.doUpdateNickname(); })
            }
            .width('100%')
            .margin({ top: 12 })
          }
          .width('80%')
          .padding(16)
          .backgroundColor('#ffffff')
          .borderRadius(10)
          .border({ width: 1, color: '#e8e8e8' })
          .margin({ bottom: 16 })
        }

        // 修改密码
        Button('修改密码')
          .width('70%')
          .height(44)
          .fontSize(15)
          .backgroundColor('#f0f0f0')
          .fontColor('#333')
          .borderRadius(8)
          .margin({ bottom: 8 })
          .onClick(() => { this.showPwdEdit = !this.showPwdEdit; })

        if (this.showPwdEdit) {
          Column() {
            TextInput({ placeholder: '原密码' })
              .width('100%').height(44).fontSize(15)
              .backgroundColor('#f8f8f8').borderRadius(8)
              .type(InputType.Password)
              .onChange((v: string) => { this.oldPwd = v; })

            TextInput({ placeholder: '新密码(6-20位)' })
              .width('100%').height(44).fontSize(15)
              .backgroundColor('#f8f8f8').borderRadius(8)
              .type(InputType.Password)
              .margin({ top: 10 })
              .onChange((v: string) => { this.newPwd = v; })

            Row() {
              Button('取消')
                .fontSize(14).backgroundColor('#f0f0f0').fontColor('#333')
                .layoutWeight(1).margin({ right: 8 })
                .onClick(() => { this.showPwdEdit = false; })

              Button('确认修改')
                .fontSize(14).backgroundColor('#e74c3c')
                .layoutWeight(1).margin({ left: 8 })
                .onClick(() => { this.doUpdatePassword(); })
            }
            .width('100%').margin({ top: 12 })
          }
          .width('80%').padding(16)
          .backgroundColor('#ffffff').borderRadius(10)
          .border({ width: 1, color: '#e8e8e8' })
          .margin({ bottom: 16 })
        }

        Blank()

        // 退出登录
        Button('退出登录')
          .width('60%')
          .height(44)
          .fontSize(15)
          .backgroundColor('#ffffff')
          .fontColor('#e74c3c')
          .border({ width: 1, color: '#e74c3c' })
          .borderRadius(22)
          .margin({ bottom: 40 })
          .onClick(() => { this.doLogout(); })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8f8f8')
  }
}
