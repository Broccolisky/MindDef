/**
 * Token 管理工具 —— Preferences 持久化存储
 *
 * - 登录成功 → 存储 token + userId + nickname
 * - 每次请求 → 从 Preferences 读取 token
 * - 收到 401 / 退出登录 → 清除本地数据
 */
import { preferences } from '@kit.ArkData';

const PREF_NAME: string = 'minddef_prefs';

/**
 * 保存登录信息
 */
export async function saveLoginInfo(token: string, userId: number, nickname: string): Promise<void> {
  try {
    let prefs = await preferences.getPreferences(getContext(), PREF_NAME);
    await prefs.put('token', token);
    await prefs.put('userId', userId);
    await prefs.put('nickname', nickname);
    await prefs.flush();
  } catch (e) {
    console.error('保存登录信息失败:', JSON.stringify(e));
  }
}

/**
 * 获取 Token
 */
export async function getToken(): Promise<string> {
  try {
    let prefs = await preferences.getPreferences(getContext(), PREF_NAME);
    return await prefs.get('token', '') as string;
  } catch (e) {
    return '';
  }
}

/**
 * 获取用户 ID
 */
export async function getUserId(): Promise<number> {
  try {
    let prefs = await preferences.getPreferences(getContext(), PREF_NAME);
    return await prefs.get('userId', 0) as number;
  } catch (e) {
    return 0;
  }
}

/**
 * 获取昵称
 */
export async function getNickname(): Promise<string> {
  try {
    let prefs = await preferences.getPreferences(getContext(), PREF_NAME);
    return await prefs.get('nickname', '') as string;
  } catch (e) {
    return '';
  }
}

/**
 * 清除登录信息（退出登录）
 */
export async function clearLoginInfo(): Promise<void> {
  try {
    let prefs = await preferences.getPreferences(getContext(), PREF_NAME);
    await prefs.delete('token');
    await prefs.delete('userId');
    await prefs.delete('nickname');
    await prefs.flush();
  } catch (e) {
    console.error('清除登录信息失败:', JSON.stringify(e));
  }
}

/**
 * 检查是否已登录
 */
export async function isLoggedIn(): Promise<boolean> {
  let token: string = await getToken();
  return token !== '';
}
