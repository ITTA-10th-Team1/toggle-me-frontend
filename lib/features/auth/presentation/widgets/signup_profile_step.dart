import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/signup_request.dart';
import 'primary_button.dart';
import 'signup_dropdown.dart';
import 'signup_fields.dart';
import 'signup_style.dart';

/// 회원가입 1단계: 닉네임, 성별, 생년월일 (피그마 Android_앱 내 회원가입1)
/// 모두 입력하면 [다음] 버튼이 켜지고, 누르면 [onNext]로 입력값을 넘겨요.
class SignupProfileStep extends StatefulWidget {
  const SignupProfileStep({super.key, required this.onNext});

  final ValueChanged<SignupProfile> onNext;

  @override
  State<SignupProfileStep> createState() => _SignupProfileStepState();
}

class _SignupProfileStepState extends State<SignupProfileStep> {
  /// 닉네임: 한글, 영문, 숫자 2~10자
  static final _nicknamePattern = RegExp(r'^[가-힣a-zA-Z0-9]{2,10}$');

  /// 입력 중에는 한글 자음·모음(ㄱ, ㅏ)도 잠깐 생겨서 함께 허용해요.
  static final _nicknameChars = RegExp(r'[가-힣ㄱ-ㅎㅏ-ㅣa-zA-Z0-9]');

  static const _defaultYear = 2000;

  final _nicknameController = TextEditingController();
  Gender? _gender;
  int _year = _defaultYear;
  int _month = 1;
  int _day = 1;

  String get _nickname => _nicknameController.text;
  bool get _nicknameValid => _nicknamePattern.hasMatch(_nickname);
  bool get _canNext => _nicknameValid && _gender != null;

  /// 연도 목록: 올해부터 100년 전까지 (오래된 순)
  List<int> get _years {
    final thisYear = DateTime.now().year;
    return [for (var y = thisYear - 100; y <= thisYear; y++) y];
  }

  /// 그 달의 마지막 날 (2월은 윤년이면 29일)
  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  @override
  void initState() {
    super.initState();
    // 글자를 입력할 때마다 다시 그려서 [다음] 버튼·안내 색을 갱신해요.
    _nicknameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  /// 연·월을 바꿨을 때 날짜가 그 달에 없으면(예: 2월 31일) 마지막 날로 맞춰요.
  void _setDate({int? year, int? month, int? day}) {
    setState(() {
      _year = year ?? _year;
      _month = month ?? _month;
      _day = (day ?? _day).clamp(1, _daysInMonth);
    });
  }

  void _onNext() {
    FocusScope.of(context).unfocus();
    widget.onNext(
      SignupProfile(
        nickname: _nickname,
        gender: _gender!,
        birthDate: DateTime(_year, _month, _day),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showNicknameError = _nickname.isNotEmpty && !_nicknameValid;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              SignupStyle.screenPadding,
              SignupStyle.barToLabel,
              SignupStyle.screenPadding,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SignupLabel('닉네임'),
                const SizedBox(height: SignupStyle.labelToField),
                SignupTextField(
                  controller: _nicknameController,
                  hintText: '닉네임을 입력해주세요',
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(_nicknameChars),
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: SignupStyle.fieldToHelper),
                SignupHelper(
                  '한글, 영문, 숫자 2~10자',
                  color: showNicknameError ? SignupStyle.error : null,
                ),
                const SizedBox(height: SignupStyle.sectionGap),
                const SignupLabel('성별'),
                const SizedBox(height: SignupStyle.labelToField),
                _buildGender(),
                const SizedBox(height: SignupStyle.sectionGap),
                const SignupLabel('생년월일'),
                const SizedBox(height: SignupStyle.labelToField),
                _buildBirthDate(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            SignupStyle.screenPadding,
            0,
            SignupStyle.screenPadding,
            16,
          ),
          child: PrimaryButton(
            text: '다음',
            onPressed: _canNext ? _onNext : null,
          ),
        ),
      ],
    );
  }

  Widget _buildGender() {
    return Row(
      children: [
        for (final (gender, label) in [
          (Gender.male, '남성'),
          (Gender.female, '여성'),
        ]) ...[
          if (gender != Gender.male)
            const SizedBox(width: SignupStyle.buttonGap),
          Expanded(
            child: SignupChoiceButton(
              label: label,
              selected: _gender == gender,
              onTap: () => setState(() => _gender = gender),
            ),
          ),
        ],
      ],
    );
  }

  /// 연도 칸이 조금 더 넓어요. (피그마 비율 약 9 : 7 : 7)
  Widget _buildBirthDate() {
    return Row(
      children: [
        Expanded(
          flex: 9,
          child: SignupDropdown(
            key: const ValueKey('birth_year'),
            values: _years,
            value: _year,
            unit: '년',
            onChanged: (year) => _setDate(year: year),
          ),
        ),
        const SizedBox(width: SignupStyle.buttonGap),
        Expanded(
          flex: 7,
          child: SignupDropdown(
            key: const ValueKey('birth_month'),
            values: [for (var m = 1; m <= 12; m++) m],
            value: _month,
            unit: '월',
            onChanged: (month) => _setDate(month: month),
          ),
        ),
        const SizedBox(width: SignupStyle.buttonGap),
        Expanded(
          flex: 7,
          child: SignupDropdown(
            key: const ValueKey('birth_day'),
            values: [for (var d = 1; d <= _daysInMonth; d++) d],
            value: _day,
            unit: '일',
            onChanged: (day) => _setDate(day: day),
          ),
        ),
      ],
    );
  }
}
