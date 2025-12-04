import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const brandBlue = Color(0xFF0E5AA6);

  // Card form
  final GlobalKey<FormState> _cardFormKey = GlobalKey<FormState>();
  final _holderCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _expCtrl = TextEditingController(); // MM/YY
  final _cvvCtrl = TextEditingController(); // 3 digits

  // PayPal (simple logical info: email)
  final GlobalKey<FormState> _paypalFormKey = GlobalKey<FormState>();
  final _paypalEmailCtrl = TextEditingController();

  String _method = 'card'; // 'card' | 'paypal'
  bool _saveForFuture = false;

  @override
  void dispose() {
    _holderCtrl.dispose();
    _numberCtrl.dispose();
    _expCtrl.dispose();
    _cvvCtrl.dispose();
    _paypalEmailCtrl.dispose();
    super.dispose();
  }

  // ============== Firebase helpers ==============

  String get _uid {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      throw StateError('No logged-in user. Please sign in first.');
    }
    return u.uid;
  }

  CollectionReference<Map<String, dynamic>> get _pmCol => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_uid)
      .collection('paymentMethods');

  Future<bool> _saveCardToFirestore({
    required String holderName,
    required String cardNumber, // we will store only brand + last4
    required String exp, // MM/YY
    required bool saved,
  }) async {
    try {
      final digits = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final last4 = digits.length >= 4
          ? digits.substring(digits.length - 4)
          : digits;
      final brand = _detectBrand(digits);
      final parts = exp.split('/');
      final mm = parts.isNotEmpty ? parts[0].padLeft(2, '0') : '';
      final rawYear = parts.length > 1 ? parts[1] : '';
      final yyyy = rawYear.length == 2 ? '20$rawYear' : rawYear;
      await _pmCol.doc().set({
        'type': 'card',
        'holderName': holderName,
        'brand': brand,
        'last4': last4,
        'expMonth': mm,
        'expYear': yyyy,
        'saved': saved, // true if user checked “save for future”
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _savePayPalToFirestore({
    required String email,
    required bool saved,
  }) async {
    try {
      await _pmCol.doc().set({
        'type': 'paypal',
        'email': email,
        'saved': saved,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  String _detectBrand(String digits) {
    if (digits.startsWith('4')) return 'Visa';
    if (RegExp(r'^(5[1-5])').hasMatch(digits)) return 'Mastercard';
    if (RegExp(r'^(3[47])').hasMatch(digits)) return 'American Express';
    if (RegExp(r'^(6(?:011|5))').hasMatch(digits)) return 'Discover';
    return 'Card';
  }

  // ============== Validators/formatters helpers ==============

  String? _validateExp(String? v) {
    final s = (v ?? '').trim();
    // Must be MM/YY
    final expReg = RegExp(r'^(0[1-9]|1[0-2])/\d{2}$');
    if (!expReg.hasMatch(s)) return 'MM/YY';

    final parts = s.split('/');
    final mm = int.parse(parts[0]);
    final yy2 = int.parse(parts[1]); // 00..99
    final yyyy = 2000 + yy2;

    // Reject any year before 2026
    if (yyyy < 2026) return 'Expiry must be 2026 or later';

    // Optional: also reject past months in the same year (keeps your 2026 minimum too)
    final now = DateTime.now();
    if (yyyy == now.year && mm < now.month) return 'Card expired';

    return null;
  }

  String? _validateCvv(String? v) {
    final s = (v ?? '').trim();
    if (s.length != 3) return '3 digits';
    return null;
  }

  String? _validateEmail(String? v) {
    final s = (v ?? '').trim();
    final r = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!r.hasMatch(s)) return 'Enter a valid email';
    return null;
  }

  Future<void> _notifyAndBack({
    required bool success,
    required String okMsg,
    required String failMsg,
  }) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? okMsg : failMsg),
        backgroundColor: success
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626), // green/red
      ),
    );
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.pop(context, success);
  }

  bool _adding = false;
  final Duration _addCooldown = const Duration(seconds: 1);
  DateTime? _nextAddAllowed;

  bool get _addCoolingDown =>
      _nextAddAllowed != null && DateTime.now().isBefore(_nextAddAllowed!);

  void _startAddCooldown() {
    _nextAddAllowed = DateTime.now().add(_addCooldown);
  }

  Future<void> _onAdd() async {
    if (_adding || _addCoolingDown) return; // guard

    try {
      if (_method == 'paypal') {
        if (_paypalFormKey.currentState?.validate() != true) return;
        setState(() => _adding = true);
        _startAddCooldown();
        final success = await _savePayPalToFirestore(
          email: _paypalEmailCtrl.text.trim(),
          saved: _saveForFuture,
        );
        await _notifyAndBack(
          success: success,
          okMsg: 'PayPal added successfully',
          failMsg: 'Failed to add PayPal',
        );
        return;
      }

      // Card
      if (_cardFormKey.currentState?.validate() != true) return;
      setState(() => _adding = true);
      _startAddCooldown();
      final success = await _saveCardToFirestore(
        holderName: _holderCtrl.text.trim(),
        cardNumber: _numberCtrl.text.trim(),
        exp: _expCtrl.text.trim(),
        saved: _saveForFuture,
      );
      await _notifyAndBack(
        success: success,
        okMsg: 'Card added successfully',
        failMsg: 'Failed to add card',
      );
    } catch (_) {
      await _notifyAndBack(
        success: false,
        okMsg: '',
        failMsg: 'Something went wrong',
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF0E5AA6);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FB),
      body: SafeArea(
        child: Column(
          children: [
            const _Header(title: 'Add New Payment Method'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _MethodTile(
                    label: 'Credit Card',
                    imageAsset: 'assets/images/visa.png', // Ensure asset exists or change
                    selected: _method == 'card',
                    onTap: () => setState(() => _method = 'card'),
                  ),
                  const SizedBox(height: 12),
                  _MethodTile(
                    label: 'PayPal',
                    imageAsset: 'assets/images/paypal.png', // Ensure asset exists or change
                    selected: _method == 'paypal',
                    onTap: () => setState(() => _method = 'paypal'),
                  ),
                  const SizedBox(height: 14),
                  const Divider(thickness: 1),
                  const SizedBox(height: 14),

                  // CARD FORM
                  if (_method == 'card')
                    Form(
                      key: _cardFormKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Card Holder Name'),
                          _Input(
                            controller: _holderCtrl,
                            hint: 'Enter name here',
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 14),

                          const _FieldLabel('Card Number'),
                          _Input(
                            controller: _numberCtrl,
                            hint: '0000 0000 0000 0000',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(19),
                              _CardNumberFormatter(),
                            ],
                            validator: (v) {
                              final digits = (v ?? '').replaceAll(
                                RegExp(r'[^0-9]'),
                                '',
                              );
                              if (digits.length < 12) return 'Invalid number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel('Expiration Date'),
                                    _Input(
                                      controller: _expCtrl,
                                      hint: 'MM/YY',
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                        _ExpiryFormatter(),
                                      ],
                                      validator: _validateExp,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel('CVV'),
                                    _Input(
                                      controller: _cvvCtrl,
                                      hint: 'CVV',
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(3),
                                      ],
                                      validator: _validateCvv,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                  // PAYPAL FORM (simple email capture)
                  if (_method == 'paypal')
                    Form(
                      key: _paypalFormKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('PayPal Email'),
                          _Input(
                            controller: _paypalEmailCtrl,
                            hint: 'email@example.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                  // Save checkbox (applies to both methods)
                  Row(
                    children: [
                      Checkbox(
                        value: _saveForFuture,
                        onChanged: (v) =>
                            setState(() => _saveForFuture = v ?? false),
                        activeColor: brandBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(color: Colors.black26),
                        ),
                      ),
                      const Expanded(
                        child: Text('Save Card Securely For Future Payments'),
                      ),
                    ],
                  ),
                  const Divider(thickness: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 130,
                        height: 33,
                        child: OutlinedButton(
                          onPressed: () {
                            context.pop(); // FIXED: Using context.pop() instead of navigation
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 130,
                        height: 33,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: (_adding || _addCoolingDown)
                              ? null
                              : _onAdd,
                          child: _adding
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _method == 'paypal'
                                      ? 'Add PayPal'
                                      : 'Add Card',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Header: logo + back + title
class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF0E5AA6);
    return Container(
      color: const Color(0xFFF2F7FB),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        children: [
          // Logo
          SizedBox(
            height: 56,
            child: Center(
              child: Image.asset(
                'assets/images/logo_medlink.png',
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Back + title centered
          SizedBox(
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: brandBlue,
                      size: 28,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// Payment method tile
class _MethodTile extends StatelessWidget {
  final String label;
  final String imageAsset;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.label,
    required this.imageAsset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF0E5AA6);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? brandBlue : Colors.black12,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Safe image loading in case asset is missing
            Image.asset(
              imageAsset, 
              height: 22,
              errorBuilder: (ctx, err, stack) => const Icon(Icons.payment, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? brandBlue : Colors.black45,
                  width: 2,
                ),
              ),
              child: selected
                  ? Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: brandBlue,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// Label + input
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  const _Input({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black26),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black26),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0E5AA6), width: 1.5),
        ),
      ),
    );
  }
}

// Format 0000 0000 0000 0000 while typing
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buf.write(digits[i]);
      if ((i + 1) % 4 == 0 && i + 1 != digits.length) buf.write(' ');
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// Format MM/YY while typing and clamp month to 01..12
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);

    String mm = '';
    String yy = '';
    if (digits.length >= 2) {
      mm = digits.substring(0, 2);
      yy = digits.substring(2);
    } else {
      mm = digits;
    }

    // Normalize month
    if (mm.length == 1) {
      // user typed 3..9 as first digit -> prepend 0
      final m = int.tryParse(mm) ?? 0;
      if (m > 1) mm = '0$mm';
    }
    if (mm.length == 2) {
      final m = int.tryParse(mm) ?? 0;
      if (m == 0) mm = '01';
      if (m > 12) mm = '12';
    }

    final text = yy.isEmpty ? mm : '$mm/$yy';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}