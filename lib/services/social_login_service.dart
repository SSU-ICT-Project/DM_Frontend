import 'dart:convert';
import 'package:flutter_naver_login/interface/types/naver_account_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:flutter_naver_login/interface/types/naver_token.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SocialLoginService {
  static String get _baseUrl {
    final url = dotenv.env['BACKEND_BASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('BACKEND_BASE_URL 환경변수가 설정되지 않았습니다. .env 파일을 확인해주세요.');
    }
    return url;
  }
  
  // 구글 로그인
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        throw Exception('구글 로그인이 취소되었습니다.');
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      
      // 백엔드로 토큰 전송
      final response = await http.post(
        Uri.parse('$_baseUrl/rest-api/v1/oauth2/app/google'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'access_token': auth.accessToken,
          'id_token': auth.idToken,
          'email': account.email,
          'display_name': account.displayName,
          'photo_url': account.photoUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'user_data': data,
          'provider': 'google',
        };
      } else {
        throw Exception('백엔드 인증 실패: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'provider': 'google',
      };
    }
  }

  // 카카오 로그인
  static Future<Map<String, dynamic>?> signInWithKakao() async {
    try {
      // 카카오톡으로 로그인 시도
      OAuthToken token;
      try {
        print('카카오톡으로 로그인 시도...');
        token = await UserApi.instance.loginWithKakaoTalk();
        print('카카오톡 로그인 성공');
      } catch (e) {
        print('카카오톡 로그인 실패, 카카오계정으로 로그인 시도: $e');
        // 카카오톡 미설치 시 카카오계정으로 로그인
        token = await UserApi.instance.loginWithKakaoAccount();
        print('카카오계정 로그인 성공');
      }

      // 사용자 정보 조회
      print('사용자 정보 조회 중...');
      User user = await UserApi.instance.me();
      print('사용자 정보 조회 성공: ${user.id}');
      
      // 백엔드로 토큰 전송
      print('백엔드로 토큰 전송 중...');
      final response = await http.post(
        Uri.parse('$_baseUrl/rest-api/v1/oauth2/app/kakao'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'access_token': token.accessToken,
          'refresh_token': token.refreshToken,
          'user_id': user.id.toString(),
          'email': user.kakaoAccount?.email,
          'nickname': user.kakaoAccount?.profile?.nickname,
          'profile_image_url': user.kakaoAccount?.profile?.profileImageUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('백엔드 인증 성공');
        return {
          'success': true,
          'user_data': data,
          'provider': 'kakao',
        };
      } else {
        throw Exception('백엔드 인증 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('카카오 로그인 오류: $e');
      return {
        'success': false,
        'error': e.toString(),
        'provider': 'kakao',
      };
    }
  }

  // 네이버 로그인
  static Future<Map<String, dynamic>?> signInWithNaver() async {
    try {
      final NaverLoginResult result = await FlutterNaverLogin.logIn();
      
      if (result.status == NaverLoginStatus.loggedIn && result.account != null) {
        // 현재 액세스 토큰 가져오기
        final NaverToken token = await FlutterNaverLogin.getCurrentAccessToken();
        
        // 백엔드로 토큰 전송
        final response = await http.post(
          Uri.parse('$_baseUrl/rest-api/v1/oauth2/app/naver'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'access_token': token.accessToken,
            'refresh_token': token.refreshToken,
            'token_type': token.tokenType,
            'expires_at': token.expiresAt,
            'user_id': result.account!.id,
            'nickname': result.account!.nickname,
            'name': result.account!.name,
            'email': result.account!.email,
            'gender': result.account!.gender,
            'age': result.account!.age,
            'birthday': result.account!.birthday,
            'birthyear': result.account!.birthYear,
            'profile_image': result.account!.profileImage,
            'mobile': result.account!.mobile,
            'mobile_e164': result.account!.mobileE164,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'user_data': data,
            'provider': 'naver',
          };
        } else {
          throw Exception('백엔드 인증 실패: ${response.statusCode}');
        }
      } else {
        throw Exception('네이버 로그인 실패: ${result.status}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'provider': 'naver',
      };
    }
  }

  // 로그아웃
  static Future<void> signOut(String provider) async {
    try {
      switch (provider) {
        case 'google':
          await GoogleSignIn().signOut();
          break;
        case 'kakao':
          await UserApi.instance.logout();
          print('카카오 로그아웃 완료');
          break;
        case 'naver':
          await FlutterNaverLogin.logOut();
          break;
      }
    } catch (e) {
      print('로그아웃 중 오류 발생: $e');
    }
  }
}
