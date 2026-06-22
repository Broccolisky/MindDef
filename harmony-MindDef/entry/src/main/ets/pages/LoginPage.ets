/**
 * 登录页面
 *
 * - 用户名 + 密码登录
 * - 登录成功 → 存储 Token → 跳转首页
 * - 底部"去注册"链接
 */
import { promptAction } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { post } from '../utils/HttpUtil';
import { saveLoginInfo } from '../utils/TokenUtil';

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State loading: boolean = false;

  build() {
    Column() {
      // ── 标题区 ──
      Column() {
        Text('MindDef')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1a1a1a')
          .margin({ bottom: 8 })

        Text('你的决策助手')
          .fontSize(14)
          .fontColor('#999')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 80, bottom: 48 })

      // ── 输入区 ──
      Column() {
        // 用户名
        TextInput({ placeholder: '请输入用户名' })
          .width('100%')
          .height(48)
          .fontSize(16)
          .backgroundColor('#f8f8f8')
          .borderRadius(8)
          .onChange((value: string) => {
            this.username = value;
          })

        // 密码
        TextInput({ placeholder: '请输入密码' })
          .width('100%')
          .height(48)
          .fontSize(16)
          .backgroundColor('#f8f8f8')
          .borderRadius(8)
          .type(InputType.Password)
          .margin({ top: 16 })
          .onChange((value: string) => {
            this.password = value;
          })
      }
      .width('100%')
      .padding({ left: 32, right: 32 })

      // ── 登录按钮 ──
      Button(this.loading ? '登录中...' : '登  录')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(this.canLogin() ? '#4a90d9' : '#ccc')
        .borderRadius(24)
        .margin({ top: 32, left: 32, right: 32 })
        .enabled(this.canLogin() && !this.loading)
        .onClick(() => {
          this.doLogin();
        })

      // ── 底部链接 ──
      Row() {
        Text('没有账号？')
          .fontSize(14)
          .fontColor('#999')
        Text('去注册')
          .fontSize(14)
          .fontColor('#4a90d9')
          .onClick(() => {
            router.pushUrl({ url: 'pages/RegisterPage' });
          })
      }
      .margin({ top: 24 })

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }

  /**
   * 判断登录按钮是否可点击
   */
  canLogin(): boolean {
    return this.username.trim() !== '' && this.password.trim() !== '';
  }

  /**
   * 执行登录
   */
  async doLogin(): Promise<void> {
    this.loading = true;
    try {
      let loginData: Record<string, string> = {
        'username': this.username.trim(),
        'password': this.password
      };
      let data: Record<string, Object> | null = await post('/api/auth/login', loginData) as Record<string, Object> | null;

      if (data) {
        // 校验必要字段存在
        let token: string = data['token'] as string;
        let userId: number = data['userId'] as number;
        let nickname: string = (data['nickname'] as string) || this.username.trim();
        if (!token || !userId) {
          promptAction.showToast({ message: '登录响应异常', duration: 1500 });
          return;
        }

        // 保存登录信息
        await saveLoginInfo(token, userId, nickname);

        promptAction.showToast({ message: '登录成功', duration: 1500 });

        // 跳转首页（替换当前页，不可返回）
        router.replaceUrl({ url: 'pages/Index' });
      }
    } finally {
      this.loading = false;
    }
  }
}
