import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import 'signup_style.dart';

/// 생년월일 선택 칸 (연 / 월 / 일)
/// 누르면 칸 아래로 회색 목록이 펼쳐지고, 고르면 닫혀요. (피그마 회원가입1 오른쪽 그림)
/// - 고른 값은 검정 + 단위('2000 년'), 나머지는 회색
/// - 목록 밖을 누르면 닫혀요.
class SignupDropdown extends StatefulWidget {
  const SignupDropdown({
    super.key,
    required this.values,
    required this.value,
    required this.unit,
    required this.onChanged,
  });

  final List<int> values;
  final int value;

  /// '년', '월', '일'
  final String unit;
  final ValueChanged<int> onChanged;

  /// 월·일은 두 자리로 보여줘요. (1 → '01')
  static String format(int value) => value.toString().padLeft(2, '0');

  @override
  State<SignupDropdown> createState() => _SignupDropdownState();
}

class _SignupDropdownState extends State<SignupDropdown> {
  final _overlay = OverlayPortalController();
  final _link = LayerLink();

  /// 칸과 펼친 목록을 한 묶음으로 봐서, 이 바깥을 누르면 닫혀요.
  final _tapGroup = Object();

  static const _itemHeight = 30.0;
  static const _visibleItems = 4;

  /// 펼친 목록의 스크롤. 열 때마다 고른 값이 맨 위에 오도록 새로 만들어요.
  ScrollController? _scroll;

  bool get _isOpen => _overlay.isShowing;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _close();
      return;
    }
    // 키보드가 올라와 있으면 목록을 가려서 먼저 내려요.
    FocusScope.of(context).unfocus();
    final index = widget.values.indexOf(widget.value);
    final maxOffset =
        (widget.values.length - _visibleItems).clamp(0, widget.values.length) *
        _itemHeight;
    _scroll?.dispose();
    _scroll = ScrollController(
      initialScrollOffset: (index < 0 ? 0 : index * _itemHeight)
          .clamp(0, maxOffset)
          .toDouble(),
    );
    setState(_overlay.show);
  }

  void _close() {
    if (_isOpen) setState(_overlay.hide);
  }

  void _select(int value) {
    _close();
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: _tapGroup,
      onTapOutside: (_) => _close(),
      child: CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: _overlay,
          overlayChildBuilder: _buildMenu,
          child: _Header(
            text: SignupDropdown.format(widget.value),
            semanticLabel:
                '${SignupDropdown.format(widget.value)}${widget.unit}',
            onTap: _toggle,
          ),
        ),
      ),
    );
  }

  /// 펼친 목록: 칸 바로 밑에 회색 상자를 깔고, 그 위에 칸을 한 번 더 그려요.
  Widget _buildMenu(BuildContext overlayContext) {
    final width = (context.findRenderObject()! as RenderBox).size.width;
    const fieldHeight = SignupStyle.controlHeight;

    return CompositedTransformFollower(
      link: _link,
      showWhenUnlinked: false,
      child: Align(
        alignment: Alignment.topLeft,
        child: TapRegion(
          groupId: _tapGroup,
          child: SizedBox(
            width: width,
            child: Stack(
              children: [
                // 회색 목록 상자 (칸의 가운데부터 시작해서 칸 뒤로 이어져 보여요)
                Container(
                  margin: const EdgeInsets.only(top: fieldHeight / 2),
                  padding: const EdgeInsets.only(
                    top: fieldHeight / 2 + 4,
                    bottom: 8,
                  ),
                  decoration: const BoxDecoration(
                    color: SignupStyle.fieldBackground,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(SignupStyle.menuRadius),
                    ),
                  ),
                  child: SizedBox(
                    height: _itemHeight * _visibleItems,
                    child: Material(
                      type: MaterialType.transparency,
                      child: ListView.builder(
                        controller: _scroll,
                        padding: EdgeInsets.zero,
                        itemExtent: _itemHeight,
                        itemCount: widget.values.length,
                        itemBuilder: (_, i) => _buildItem(widget.values[i]),
                      ),
                    ),
                  ),
                ),
                _Header(
                  text: SignupDropdown.format(widget.value),
                  semanticLabel:
                      '${SignupDropdown.format(widget.value)}${widget.unit}',
                  onTap: _close,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int value) {
    final selected = value == widget.value;
    final text = SignupDropdown.format(value);

    return InkWell(
      onTap: () => _select(value),
      child: Padding(
        padding: const EdgeInsets.only(left: SignupStyle.textInset),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            selected ? '$text ${widget.unit}' : text,
            style: SignupStyle.dropdown.copyWith(
              color: selected ? AppColors.textPrimary : SignupStyle.grayText,
            ),
          ),
        ),
      ),
    );
  }
}

/// 생년월일 칸 겉모습: 흰 바탕, 검정 테두리, 오른쪽 화살표
class _Header extends StatelessWidget {
  const _Header({
    required this.text,
    required this.semanticLabel,
    required this.onTap,
  });

  final String text;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: AppColors.white,
        shape: const StadiumBorder(
          side: BorderSide(color: AppColors.authBlack),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: SignupStyle.controlHeight,
            child: Padding(
              padding: const EdgeInsets.only(
                left: SignupStyle.textInset,
                right: 16,
              ),
              child: Row(
                children: [
                  Expanded(child: Text(text, style: SignupStyle.dropdown)),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.authBlack,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
