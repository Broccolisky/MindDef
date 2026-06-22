/**
 * 注册页面
 *
 * - 用户名 + 密码 + 确认密码
 * - 前端校验：非空 / 用户名格式 / 密码长度 / 两次密码一致
 * - 注册成功 → 跳转登录页
 */
import { promptAction } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { post } from '../utils/HttpUtil';

@Entry
@Component
struct RegisterPage {
  @State username: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State loading: boolean = false;

  // 字段错误提示
  @State usernameError: string = '';
  @State passwordError: string = '';
  @State confirmError: string = '';

  build() {
    Column() {
      // ── 标题区 ──
      Column() {
        Text('注册 MindDef')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1a1a1a')
          .margin({ bottom: 8 })

        Text('4-16位字母数字下划线')
          .fontSize(13)
          .fontColor('#999')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 60, bottom: 36 })

      // ── 输入区 ──
      Column() {
        // 用户名
        TextInput({ placeholder: '4-16位字母数字下划线' })
          .width('100%')
          .height(48)
          .fontSize(16)
          .backgroundColor('#f8f8f8')
          .borderRadius(8)
          .onChange((value: string) => {
            this.username = value;
            this.usernameError = '';
          })

        if (this.usernameError) {
          Text(this.usernameError)
            .fontSize(12)
            .fontColor('#e74c3c')
            .margin({ top: 4, left: 4 })
            .width('100%')
        }

        // 密码
        TextInput({ placeholder: '6-20位密码' })
          .width('100%')
          .height(48)
          .fontSize(16)
          .backgroundColor('#f8f8f8')
          .borderRadius(8)
          .type(InputType.Password)
          .margin({ top: 16 })
          .onChange((value: string) => {
            this.password = value;
            this.passwordError = '';
          })

        if (this.passwordError) {
          Text(this.passwordError)
            .fontSize(12)
            .fontColor('#e74c3c')
            .margin({ top: 4, left: 4 })
            .width('100%')
        }

        // 确认密码
        TextInput({ placeholder: '再次输入密码' })
          .width('100%')
          .height(48)
          .fontSize(16)
          .backgroundColor('#f8f8f8')
          .borderRadius(8)
          .type(InputType.Password)
          .margin({ top: 16 })
          .onChange((value: string) => {
            this.confirmPassword = value;
            this.confirmError = '';
          })

        if (this.confirmError) {
          Text(this.confirmError)
            .fontSize(12)
            .fontColor('#e74c3c')
            .margin({ top: 4, left: 4 })
            .width('100%')
        }
      }
      .width('100%')
      .padding({ left: 32, right: 32 })

      // ── 注册按钮 ──
      Button(this.loading ? '注册中...' : '注  册')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(this.canRegister() ? '#4a90d9' : '#ccc')
        .borderRadius(24)
        .margin({ top: 32, left: 32, right: 32 })
        .enabled(this.canRegister() && !this.loading)
        .onClick(() => {
          this.doRegister();
        })

      // ── 底部链接 ──
      Row() {
        Text('已有账号？')
          .fontSize(14)
          .fontColor('#999')
        Text('去登录')
          .fontSize(14)
          .fontColor('#4a90d9')
          .onClick(() => {
            router.back();
          })
      }
      .margin({ top: 24 })

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }

  /**
   * 前端校验
   */
  validate(): boolean {
    let valid: boolean = true;

    // 用户名校验
    let usernameRegex: RegExp = /^[a-zA-Z0-9_]{4,16}$/;
    if (!this.username.trim()) {
      this.usernameError = '用户名不能为空';
      valid = false;
    } else if (!usernameRegex.test(this.username.trim())) {
      this.usernameError = '用户名须4-16位字母数字下划线';
      valid = false;
    }

    // 密码校验
    if (!this.password) {
      this.passwordError = '密码不能为空';
      valid = false;
    } else if (this.password.length < 6 || this.password.length > 20) {
      this.passwordError = '密码须6-20位';
      valid = false;
    }

    // 确认密码校验
    if (this.password !== this.confirmPassword) {
      this.confirmError = '两次密码不一致';
      valid = false;
    }

    return valid;
  }

  canRegister(): boolean {
    return this.username.trim() !== '' && this.password !== '' && this.confirmPassword !== '';
  }

  /**
   * 执行注册
   */
  async doRegister(): Promise<void> {
    if (!this.validate()) {
      return;
    }

    this.loading = true;
    try {
      let registerData: Record<string, string> = {
        'username': this.username.trim(),
        'password': this.password
      };
      let result: object | null = await post('/api/auth/register', registerData);

      if (result !== null) {
        promptAction.showToast({ message: '注册成功，请登录', duration: 1500 });
        router.back();
      }
    } finally {
      this.loading = false;
    }
  }
}
