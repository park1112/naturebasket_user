import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../config/theme.dart';

/// 스크롤 시 앱바가 부드럽게 슬라이드 되는 위젯
class ScrollableAppBar extends StatefulWidget {
  /// 자식 위젯 (메인 콘텐츠)
  final Widget child;

  /// 앱바 제목
  final String title;

  /// 뒤로가기 버튼 표시 여부
  final bool showBackButton;

  /// 앱바 배경색
  final Color? backgroundColor;

  /// 앱바 텍스트와 아이콘 색상
  final Color? textColor;

  /// 커스텀 액션 버튼들
  final List<Widget>? actions;

  /// 앱바 타이틀 중앙 정렬 여부
  final bool centerTitle;

  /// 페이지 새로고침 콜백 함수
  final Future<void> Function()? onRefresh;

  const ScrollableAppBar({
    Key? key,
    required this.child,
    required this.title,
    this.showBackButton = true,
    this.backgroundColor,
    this.textColor,
    this.actions,
    this.centerTitle = true,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<ScrollableAppBar> createState() => _ScrollableAppBarState();
}

class _ScrollableAppBarState extends State<ScrollableAppBar>
    with SingleTickerProviderStateMixin {
  /// 스크롤 컨트롤러
  final ScrollController _scrollController = ScrollController();

  /// 앱바 애니메이션 컨트롤러
  late AnimationController _animationController;

  /// 앱바 슬라이드 애니메이션
  late Animation<Offset> _slideAnimation;

  /// 스크롤 방향 (이전 스크롤 위치 저장용)
  double _previousScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();

    // 스크롤 리스너 등록
    _scrollController.addListener(_scrollListener);

    // 애니메이션 컨트롤러 초기화 (앱바 표시/숨김 애니메이션)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // 슬라이드 애니메이션 설정 (위로 슬라이드)
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1), // 위로 슬라이드(-1)
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut, // 부드러운 애니메이션 곡선
    ));

    // 초기 상태 설정 (앱바 표시)
    _animationController.value = 0.0;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// 스크롤 이벤트 리스너
  void _scrollListener() {
    // 현재 스크롤 위치
    final currentOffset = _scrollController.offset;

    // 스크롤 방향 감지 (양수: 아래로 스크롤, 음수: 위로 스크롤)
    final scrollDelta = currentOffset - _previousScrollOffset;

    // 이전 스크롤 위치 업데이트
    _previousScrollOffset = currentOffset;

    // 아래로 스크롤하면 앱바를 숨기고, 위로 스크롤하면 앱바를 표시
    if (scrollDelta > 3 && currentOffset > 50) {
      // 아래로 스크롤 중이고, 일정 거리 이상 스크롤했으면 앱바 숨김
      if (!_animationController.isAnimating) {
        _animationController.forward(); // 앱바 숨김 애니메이션 시작
      }
    } else if (scrollDelta < -3 || currentOffset < 10) {
      // 위로 스크롤 중이거나, 맨 위 근처에 있으면 앱바 표시
      if (!_animationController.isAnimating) {
        _animationController.reverse(); // 앱바 표시 애니메이션 시작
      }
    }
  }

  /// 새로고침 기능
  Future<void> _handleRefresh() async {
    // 앱바 표시 상태로 변경
    _animationController.reverse();

    // 새로고침 콜백이 있으면 호출
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBarColor = widget.backgroundColor ?? AppTheme.primaryColor;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 스크롤 가능한 콘텐츠
          RefreshIndicator(
            onRefresh: _handleRefresh,
            color: appBarColor,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                physics: const BouncingScrollPhysics(),
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // 상태바 및 앱바 높이만큼 패딩 추가
                    SizedBox(height: statusBarHeight + kToolbarHeight),
                    // 실제 콘텐츠
                    widget.child,
                  ],
                ),
              ),
            ),
          ),

          // 애니메이션 적용된 앱바
          SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: Colors.transparent,
              elevation: 0,
              child: Container(
                height: statusBarHeight + kToolbarHeight,
                color: appBarColor,
                child: Padding(
                  padding: EdgeInsets.only(top: statusBarHeight),
                  child: Row(
                    children: [
                      // 뒤로가기 버튼
                      if (widget.showBackButton)
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: widget.textColor ?? Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Get.back(),
                        ),

                      // 타이틀 (중앙 정렬 여부에 따라 다름)
                      if (widget.centerTitle)
                        Expanded(
                          child: Center(
                            child: Text(
                              widget.title,
                              style: TextStyle(
                                color: widget.textColor ?? Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              color: widget.textColor ?? Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),

                      // 액션 버튼들
                      if (widget.actions != null)
                        ...widget.actions!
                      else
                        const SizedBox(width: 48), // 뒤로가기 버튼과 균형을 맞추기 위한 공간
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
