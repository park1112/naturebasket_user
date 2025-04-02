# 다중 로그인 템플릿 앱 (v1.2.1)

## 주요 기능
- 네이버, 페이스북, 구글 소셜 로그인
- 전화번호 인증 로그인
- 사용자 프로필 관리 (이름, 프로필 이미지)
- 로그인 기록 관리
- 자동 로그인 및 로그아웃
- 계정 삭제 (30일 보관 정책 적용)

## 버전 히스토리
- **v1.0.0 (초기 출시)**
  - 기본 앱 구조 설정
  - Firebase 연결 및 인증 기능 구현
- **v1.1.0**
  - 소셜 로그인 기능 추가 (네이버, 페이스북)
  - 프로필 관리 기능 구현 및 UI 개선
- **v1.2.0**
  - 구글 로그인 추가
  - 전화번호 인증 개선 및 UI/UX 개선
- **v1.2.1 (현재 버전)**
  - 프로필 화면 사용자 정보 불러오기 문제 수정  
    * FirestoreService의 getUser() 메서드 수정  
    * AuthController의 데이터 로드 지연 추가  
  - 로그인 기록 표시 기능 개선
  - 사용자 삭제 기능 개선 및 예외 처리 강화
  - **계정 삭제 시, 프로필 이미지 삭제 대신 삭제 보관함(deleted_profile_images)으로 이동**  
    삭제된 파일은 30일간 보관되며, 별도의 스케줄러(예: Firebase Cloud Functions)를 통해 30일 이후 완전 삭제 예정
  - 다양한 버그 수정 및 인증 프로세스 안정성 향상
  - 계정삭제까지 완료
  - **계정 삭제 후 로그인 버튼에서 무한 로딩중인 현상 해결해야함**

## 사용자 삭제 기능 개선
- **문제점**: 로그인 후 계정 삭제 시, Firebase Storage에서 파일이 없을 경우 발생하는 `object-not-found` 예외 및 기타 삭제 관련 예외들이 발생함.
- **해결 방법**:  
  - 프로필 이미지가 존재하는 경우에만 파일 데이터를 읽어와서, `deleted_profile_images` 폴더로 복사한 후 원본 파일을 삭제합니다.
  - 삭제 보관함에 보관된 파일은 별도의 백그라운드 작업(예: Firebase Cloud Functions)을 통해 30일 후 영구 삭제됩니다.
  - Firestore, Firebase Auth의 삭제 과정에서도 발생하는 예외들을 세분화하여 처리하였습니다.

## 설치 및 설정
1. Flutter 환경 설정  
   ```bash
   flutter pub get


## git 업로드 방법
    ```bash
    git add .

    git commit -m "버전 1.0.0 추가"

    git branch -m main <새롭게 할때만 해야함>

    git tag -a v1.0.0 -m "버전 1.0.0 릴리즈"

    그 태그의 이름을 v1.0.0으로 지정하며
    버전 1.0.0 릴리즈"라는 메시지를 함께 저장한다는 의미입니다

    
    git push origin main 기본 브랜치 업데이트

    git push origin --tags 태그들 모두 푸시


## 첫 commit 할때 


해결 방법
1. 먼저 GitHub에서 빈 저장소를 만든 뒤 주소를 복사해주세요.
예시 URL 형태:
   ```bash
    https://github.com/<계정명>/naturebasket_user-main.git

    2. 그 다음 로컬 저장소에서 Remote를 설정합니다.
    git remote add origin https://github.com/park1112/naturebasket_user.git
   
    3. 이제 다시 push 해주세요.
    git push -u origin main
    이 과정 이후에는 다시 에러 없이 push 됩니다.