/**
 * 统一网络请求工具
 *
 * - 自动携带 JWT Token（从 Preferences 读取）
 * - 统一处理 401 → 跳转登录页
 * - 统一处理 code != 0 → Toast 提示
 * - 返回 data 字段
 */
import { http } from '@kit.NetworkKit';
import { preferences } from '@kit.ArkData';
import { promptAction } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';

const BASE_URL: string = 'http://47.239.55.169:8080'; // 远程服务器
const PREF_NAME: string = 'minddef_prefs';

/**
 * 从 Preferences 读取 Token
 */
async function getToken(): Promise<string> {
  try {
    let prefs = await preferences.getPreferences(getContext(), PREF_NAME);
    let token: string = await prefs.get('token', '') as string;
    return token;
  } catch (e) {
    return '';
  }
}

/**
 * 发起 HTTP 请求
 * @param url    相对路径，如 '/api/auth/login'
 * @param method GET | POST | PUT | DELETE
 * @param data  请求体（JSON 对象）
 * @returns 后端返回的 data 字段
 */
export async function request(url: string, method: string, data?: object): Promise<object | null> {
  let httpRequest = http.createHttp();
  try {
    let token: string = await getToken();

    let headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    let requestOptions: http.HttpRequestOptions = {
      method: method as http.RequestMethod,
      header: headers,
      connectTimeout: 10000,
      readTimeout: 10000
    };

    // GET 请求参数拼在 URL 上（跳过 null/undefined 值）
    let fullUrl: string = BASE_URL + url;
    if (method === 'GET' && data) {
      let params: string[] = [];
      let keys: string[] = Object.keys(data);
      for (let i = 0; i < keys.length; i++) {
        let key: string = keys[i];
        let val: Object = (data as Record<string, Object>)[key];
        if (val !== null && val !== undefined) {
          params.push(`${key}=${encodeURIComponent(String(val))}`);
        }
      }
      fullUrl += '?' + params.join('&');
    } else if (data) {
      requestOptions.extraData = JSON.stringify(data);
    }

    let response = await httpRequest.request(fullUrl, requestOptions);
    let result: Record<string, Object> = JSON.parse(response.result as string);

    // 统一处理 401 → 清除 token，跳转登录页
    if (result['code'] === 401) {
      let prefs = await preferences.getPreferences(getContext(), PREF_NAME);
      await prefs.delete('token');
      await prefs.flush();
      // 防止并发 401 多次跳转
      router.replaceUrl({ url: 'pages/LoginPage' });
      return null;
    }

    // 统一处理 code != 0 → Toast 提示
    if (result['code'] !== 0) {
      promptAction.showToast({
        message: result['msg'] as string,
        duration: 2000
      });
      return null;
    }

    return result['data'] as object;

  } catch (e) {
    promptAction.showToast({
      message: '网络异常，请检查网络连接',
      duration: 2000
    });
    return null;
  } finally {
    httpRequest.destroy();
  }
}

/**
 * GET 请求快捷方法
 */
export async function get(url: string, data?: object): Promise<object | null> {
  return request(url, 'GET', data);
}

/**
 * POST 请求快捷方法
 */
export async function post(url: string, data?: object): Promise<object | null> {
  return request(url, 'POST', data);
}

/**
 * PUT 请求快捷方法
 */
export async function put(url: string, data?: object): Promise<object | null> {
  return request(url, 'PUT', data);
}

/**
 * DELETE 请求快捷方法
 */
export async function del(url: string, data?: object): Promise<object | null> {
  return request(url, 'DELETE', data);
}
