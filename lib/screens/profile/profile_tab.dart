import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/format_helper.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final AuthController _authController = Get.find<AuthController>();
  final UserController _userController = Get.find<UserController>();

  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// 프로필 수정 모드 여부
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  void _initUserData() {
    final user = _authController.userModel.value;
    if (user != null && user.name != null) {
      _nameController.text = user.name!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmallScreen = constraints.maxWidth < 600;
        bool isWebLayout = constraints.maxWidth > 900;

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 20.0 : 40.0),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isWebLayout ? 800 : double.infinity,
                  ),
                  child: Column(
                    children: [
                      // 오른쪽 상단 수정/취소 버튼
                      _buildEditButton(),

                      // 프로필 카드
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              _buildProfileImage(isSmallScreen),
                              const SizedBox(height: 24),
                              _buildProfileInfo(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 로그아웃, 계정삭제, 저장 버튼 등
                      _buildActionButtons(),
                      const SizedBox(height: 24),

                      // 로그인 기록
                      _buildLoginHistory(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 우측 상단 수정/취소 버튼
  Widget _buildEditButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: IconButton(
        icon: Icon(_isEditing ? Icons.close : Icons.edit),
        onPressed: () {
          setState(() {
            if (_isEditing) {
              _initUserData(); // 취소 시 원복
            }
            _isEditing = !_isEditing;
          });
        },
      ),
    );
  }

  /// 프로필 이미지 (수정 모드 시 카메라 아이콘 표시)
  Widget _buildProfileImage(bool isSmallScreen) {
    final user = _authController.userModel.value;
    final selectedImage = _userController.selectedImage.value;

    double imageSize = isSmallScreen ? 120 : 160;

    return Column(
      children: [
        GestureDetector(
          onTap: _isEditing ? _userController.pickImage : null,
          child: Stack(
            children: [
              CircleAvatar(
                radius: imageSize / 2,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                backgroundImage: selectedImage != null
                    ? FileImage(selectedImage)
                    : (user?.photoURL != null
                        ? CachedNetworkImageProvider(user!.photoURL!)
                        : null) as ImageProvider?,
                child: (selectedImage == null && user?.photoURL == null)
                    ? Icon(
                        Icons.person,
                        size: imageSize / 2,
                        color: AppTheme.primaryColor,
                      )
                    : null,
              ),
              if (_isEditing)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_isEditing)
          TextButton(
            onPressed: _userController.selectedImage.value != null
                ? () => _userController.selectedImage.value = null
                : null,
            child: const Text('이미지 선택 취소'),
          ),
      ],
    );
  }

  /// 프로필 기본 정보 (이름, 로그인 방식, 이메일, 전화번호 등)
  Widget _buildProfileInfo() {
    final user = _authController.userModel.value;
    if (user == null) {
      return const Center(child: Text('사용자 정보를 불러올 수 없습니다.'));
    }

    return Column(
      children: [
        if (_isEditing)
          Form(
            key: _formKey,
            child: NameTextField(controller: _nameController),
          )
        else
          _buildInfoCard('이름', user.name ?? '이름 정보 없음'),

        // 로그인 방식
        _buildInfoCard(
            '로그인 방식', _getLoginTypeString(user.loginType.toString())),

        // 이메일
        if (user.email != null && user.email!.isNotEmpty)
          _buildInfoCard('이메일', user.email!),

        // 전화번호
        if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
          _buildInfoCard(
            '전화번호',
            FormatHelper.formatPhoneNumber(user.phoneNumber!),
          ),
      ],
    );
  }

  /// 공통 UI: 라벨/값 카드 형태
  Widget _buildInfoCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 로그인 타입 한글 변환
  String _getLoginTypeString(String loginType) {
    // 디버깅
    print('Original loginType: $loginType');

    // 문자열 포맷 정규화
    String normalizedType = loginType.toLowerCase().trim();
    if (normalizedType.contains('google')) return '구글';
    if (normalizedType.contains('facebook')) return '페이스북';
    if (normalizedType.contains('naver')) return '네이버';
    if (normalizedType.contains('phone')) return '전화번호';

    // Enum 형태인 경우
    if (loginType.contains('LoginType.')) {
      String enumValue = loginType.split('.').last.toLowerCase();
      if (enumValue == 'google') return '구글';
      if (enumValue == 'facebook') return '페이스북';
      if (enumValue == 'naver') return '네이버';
      if (enumValue == 'phone') return '전화번호';
    }

    return '알 수 없음 ($loginType)';
  }

  /// 하단 버튼들(수정 중일 때: 저장 / 평소: 로그아웃, 계정삭제)
  Widget _buildActionButtons() {
    final user = _authController.userModel.value;
    if (user == null) return const SizedBox.shrink();

    return Column(
      children: [
        if (_isEditing)
          CustomButton(
            text: '프로필 저장',
            onPressed: _saveProfile,
            icon: Icons.save,
          )
        else ...[
          CustomButton(
            text: '로그아웃',
            onPressed: _logout,
            backgroundColor: Colors.grey.shade700,
            icon: Icons.logout,
          ),
          const SizedBox(height: 15),
          CustomButton(
            text: '계정 삭제',
            onPressed: _showDeleteConfirmation,
            backgroundColor: AppTheme.errorColor,
            icon: Icons.delete,
          ),
        ],
      ],
    );
  }

  /// 프로필 저장 (이름 등)
  void _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      await _userController.updateProfile(
        name: _nameController.text.trim(),
      );

      setState(() {
        _isEditing = false;
      });
    }
  }

  /// 로그아웃
  void _logout() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _authController.signOut();
    }
  }

  /// 계정 삭제 확인
  void _showDeleteConfirmation() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('계정 삭제'),
        content: const Text(
          '계정을 삭제하면 모든 데이터가 영구적으로 삭제됩니다. 정말 삭제하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _authController.deleteAccount();
    }
  }

  /// 로그인 기록 표시
  Widget _buildLoginHistory() {
    final user = _authController.userModel.value;

    if (user == null || user.loginHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    // 펼치기/접기 상태
    final RxBool isExpanded = false.obs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        InkWell(
          onTap: () => isExpanded.toggle(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text(
                  '로그인 기록',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const Spacer(),
                Obx(
                  () => Icon(
                    isExpanded.value
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        Obx(
          () => isExpanded.value
              ? Container(
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        // 최근 5개만 표시
                        ...List.generate(
                          user.loginHistory.length > 5
                              ? 5
                              : user.loginHistory.length,
                          (index) {
                            final reversedIndex =
                                user.loginHistory.length - 1 - index;
                            final logItem = user.loginHistory[reversedIndex];
                            final loginType =
                                logItem['loginType'] as String? ?? 'unknown';
                            final timestamp = logItem['timestamp'];

                            return _buildLoginHistoryItem(
                              loginType,
                              timestamp,
                              index,
                            );
                          },
                        ),
                        // 더 보기 버튼
                        if (user.loginHistory.length > 5)
                          _buildShowMoreButton(user),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// "더 보기" 버튼 클릭 시 나머지 기록 표시
  Widget _buildShowMoreButton(UserModel user) {
    final RxBool showAllHistory = false.obs;

    return Obx(() => showAllHistory.value
        ? Column(
            children: [
              // 나머지 기록
              ...List.generate(
                user.loginHistory.length - 5,
                (index) {
                  final actualIndex = index + 5;
                  final reversedIndex =
                      user.loginHistory.length - 1 - actualIndex;
                  final logItem = user.loginHistory[reversedIndex];
                  final loginType =
                      logItem['loginType'] as String? ?? 'unknown';
                  final timestamp = logItem['timestamp'];

                  return _buildLoginHistoryItem(
                    loginType,
                    timestamp,
                    actualIndex,
                  );
                },
              ),
              // 접기
              InkWell(
                onTap: () => showAllHistory.value = false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '접기',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_up,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        : InkWell(
            onTap: () => showAllHistory.value = true,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '더 보기 (${user.loginHistory.length - 5})',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ));
  }

  /// 로그인 기록 한 줄
  Widget _buildLoginHistoryItem(
      String loginType, dynamic timestamp, int index) {
    DateTime dateTime;
    if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp is String) {
      try {
        dateTime = DateTime.parse(timestamp);
      } catch (e) {
        dateTime = DateTime.now();
      }
    } else if (timestamp is int) {
      // 타임스탬프가 숫자로 저장된 경우
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      // Firestore Timestamp 같은 경우
      try {
        dateTime = (timestamp as dynamic).toDate();
      } catch (_) {
        dateTime = DateTime.now();
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.grey.shade50 : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getLoginTypeIcon(loginType),
              color: AppTheme.primaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getLoginTypeString(loginType)} 로그인',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(dateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}년 ${dateTime.month}월 '
        '${dateTime.day}일 ${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  IconData _getLoginTypeIcon(String loginType) {
    switch (loginType) {
      case 'google':
        return Icons.account_circle;
      case 'facebook':
        return Icons.facebook;
      case 'naver':
        return Icons.app_registration;
      case 'phone':
        return Icons.phone;
      default:
        return Icons.login;
    }
  }
}
