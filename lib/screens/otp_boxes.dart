import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpBoxes extends StatefulWidget {
  final void Function(String otp) onCompleted;
  final VoidCallback? onResend;
  final bool enabled;
  final int maxAttempts;       // 0 = unlimited
  final int resendSeconds;     // countdown duration

  const OtpBoxes({
    super.key,
    required this.onCompleted,
    this.onResend,
    this.enabled = true,
    this.maxAttempts = 3,
    this.resendSeconds = 30,
  });

  @override
  State<OtpBoxes> createState() => OtpBoxesState();
}

class OtpBoxesState extends State<OtpBoxes> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  int _attempts = 0;
  int _secondsLeft = 0;
  Timer? _timer;
  int _focusedIndex = -1;

  static const _green = Color(0xFF2E7D52);

  @override
  void initState() {
    super.initState();
    _startTimer();
    for (int i = 0; i < 4; i++) {
      final idx = i;
      _focusNodes[idx].addListener(() {
        if (mounted) setState(() => _focusedIndex = _focusNodes[idx].hasFocus ? idx : (_focusedIndex == idx ? -1 : _focusedIndex));
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = widget.resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
        }
      });
    });
  }

  /// Call from parent after a failed attempt to increment counter
  void recordFailedAttempt() {
    setState(() => _attempts++);
  }

  /// Resets boxes and restarts timer — call after resend
  void reset() {
    for (final c in _controllers) c.clear();
    setState(() => _attempts = 0);
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_focusNodes[0]);
    });
  }

  bool get _isBlocked => widget.maxAttempts > 0 && _attempts >= widget.maxAttempts;

  void _onChanged(String value, int index) {
    if (_isBlocked) return;

    if (value.length > 1) {
      // Paste: distribute digits across boxes
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < 4; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final last = (digits.length - 1).clamp(0, 3);
      FocusScope.of(context).requestFocus(_focusNodes[last]);
    } else {
      // Keep only 1 digit in this box
      if (value.length > 1) _controllers[index].text = value[0];
      if (value.isNotEmpty && index < 3) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      }
    }

    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 4) widget.onCompleted(otp);
  }

  void _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
      _controllers[index - 1].clear();
    }
  }

  void _handleResend() {
    if (_secondsLeft > 0) return;
    widget.onResend?.call();
    reset();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 4 Boxes ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final isFocused = _focusedIndex == i;
            final isFilled = _controllers[i].text.isNotEmpty;
            final scale = isFocused ? 1.08 : 1.0;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 44 * scale,
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (e) => _onKeyEvent(e, i),
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  enabled: widget.enabled && !_isBlocked,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    counterText: '',
                    filled: true,
                    fillColor: _isBlocked
                        ? const Color(0xFFFEF2F2)
                        : isFocused
                            ? const Color(0xFFF0FDF4)
                            : isFilled
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFF9FAFB),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _isBlocked
                            ? Colors.red.shade200
                            : isFilled
                                ? _green.withValues(alpha: 0.5)
                                : Colors.grey.shade200,
                        width: isFilled ? 1.5 : 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _green, width: 2),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  onChanged: (v) => _onChanged(v, i),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 14),

        // ── Attempt warning ──
        if (widget.maxAttempts > 0 && _attempts > 0 && !_isBlocked)
          Text(
            '${widget.maxAttempts - _attempts} attempt${widget.maxAttempts - _attempts == 1 ? '' : 's'} remaining',
            style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.w500),
          ),

        if (_isBlocked)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 14, color: Colors.red.shade600),
                const SizedBox(width: 6),
                Text('Too many attempts. Please request a new OTP.',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w500)),
              ],
            ),
          ),

        const SizedBox(height: 14),

        // ── Resend row ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Didn't receive the code? ", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            GestureDetector(
              onTap: _secondsLeft == 0 ? _handleResend : null,
              child: _secondsLeft > 0
                  ? Text(
                      'Resend in ${_secondsLeft}s',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                    )
                  : const Text(
                      'Resend OTP',
                      style: TextStyle(fontSize: 13, color: _green, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
