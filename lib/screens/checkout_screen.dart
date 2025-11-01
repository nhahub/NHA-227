import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/payment_service.dart';

class CheckoutScreen extends StatefulWidget {
const CheckoutScreen({Key? key}) : super(key: key);

@override
State createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State {
static const brandBlue = Color(0xFF0E5AA6);

final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
final _holderCtrl = TextEditingController();
final _numberCtrl = TextEditingController();
final _expCtrl = TextEditingController();
final _cvvCtrl = TextEditingController();

String _method = 'card'; // 'card' | 'paypal'
bool _saveForFuture = false;

@override
void dispose() {
_holderCtrl.dispose();
_numberCtrl.dispose();
_expCtrl.dispose();
_cvvCtrl.dispose();
super.dispose();
}

// Show success then return to Cart
Future _successAndBack(String msg) async {
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
await Future.delayed(const Duration(milliseconds: 600));
if (!mounted) return;
Navigator.pop(context, true); // back to Cart
}

String? _validateExp(String? v) {
final s = (v ?? '').trim();
final expReg = RegExp(r'^(0[1-9]|1[0-2])/\d{2}$'); // MM/YY
if (!expReg.hasMatch(s)) return 'MM/YY';
return null;
}

Future _onAdd() async {
try {
if (_method == 'paypal') {
// No form to validate for PayPal
if (_saveForFuture) {
await PaymentService.instance.savePayPal();
}
await _successAndBack('Payment method added');
return;
}

  // Card flow
  if (_formKey.currentState?.validate() != true) return;

  if (_saveForFuture) {
    await PaymentService.instance.saveCard(
      holderName: _holderCtrl.text.trim(),
      cardNumber: _numberCtrl.text.trim(),
      exp: _expCtrl.text.trim(), // MM/YY
    );
    await _successAndBack('Card added successfully');
    return;
  }

  // If user chose not to save, still return to cart (order flow continues there)
  await _successAndBack('Payment method set');
} catch (e) {
  if (!mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('Error: $e')));
}
}

@override
Widget build(BuildContext context) {
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
// Method selector
_MethodTile(
label: 'Credit Card',
imageAsset: 'assets/images/visa.png',
selected: _method == 'card',
onTap: () => setState(() => _method = 'card'),
),
const SizedBox(height: 12),
_MethodTile(
label: 'PayPal',
imageAsset: 'assets/images/paypal.png',
selected: _method == 'paypal',
onTap: () => setState(() => _method = 'paypal'),
),
const SizedBox(height: 14),
const Divider(thickness: 1),
const SizedBox(height: 14),

              // Show card form ONLY when card selected
              if (_method == 'card')
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Card Holder Name'),
                      _Input(
                        controller: _holderCtrl,
                        hint: 'Enter name here',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                          _CardNumberFormatter(), // 0000 0000 0000 0000
                        ],
                        validator: (v) {
                          final digits =
                              (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
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
                                    _ExpiryFormatter(), // MM/YY
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
                                  validator: (v) {
                                    final s = (v ?? '').trim();
                                    if (s.length != 3) return '3 digits';
                                    return null;
                                  },
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

              // Save for future (applies to both methods)
              Row(
                children: [
                  Checkbox(
                    value: _saveForFuture,
                    onChanged: (v) => setState(() => _saveForFuture = v ?? false),
                    activeColor: brandBlue,
                  ),
                  const Expanded(
                    child: Text('Save Card Securely For Future Payments'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context, false); // back to Cart
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _onAdd,
                      child: Text(_method == 'paypal' ? 'Add PayPal' : 'Add Card'),
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
icon: const Icon(Icons.chevron_left,
color: brandBlue, size: 28),
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
Key? key,
}) : super(key: key);

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
Image.asset(imageAsset, height: 22),
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
const _FieldLabel(this.text, {Key? key}) : super(key: key);

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

const _Input({
Key? key,
required this.controller,
required this.hint,
this.keyboardType,
this.validator,
this.inputFormatters,
}) : super(key: key);

@override
Widget build(BuildContext context) {
return TextFormField(
controller: controller,
keyboardType: keyboardType,
validator: validator,
inputFormatters: inputFormatters,
decoration: InputDecoration(
hintText: hint,
filled: true,
fillColor: Colors.white,
contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

// Input formatters
class _CardNumberFormatter extends TextInputFormatter {
// Formats 0000 0000 0000 0000
@override
TextEditingValue formatEditUpdate(
TextEditingValue oldValue,
TextEditingValue newValue,
) {
final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
final buffer = StringBuffer();
for (int i = 0; i < digits.length; i++) {
buffer.write(digits[i]);
if ((i + 1) % 4 == 0 && i + 1 != digits.length) buffer.write(' ');
}
final formatted = buffer.toString();
return TextEditingValue(
text: formatted,
selection: TextSelection.collapsed(offset: formatted.length),
);
}
}

class _ExpiryFormatter extends TextInputFormatter {
// Formats MM/YY
@override
TextEditingValue formatEditUpdate(
TextEditingValue oldValue,
TextEditingValue newValue,
) {
var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
if (digits.length > 4) digits = digits.substring(0, 4);

var mm = '';
var yy = '';
if (digits.length >= 2) {
  mm = digits.substring(0, 2);
  yy = digits.substring(2);
} else {
  mm = digits;
}

// Force month between 01 and 12
if (mm.length == 1 && int.tryParse(mm) != null && int.parse(mm) > 1) {
  mm = '0$mm';
}
if (mm.length == 2) {
  final m = int.tryParse(mm) ?? 0;
  if (m == 0) mm = '01';
  if (m > 12) mm = '12';
}

final formatted = yy.isEmpty ? mm : '$mm/$yy';
return TextEditingValue(
  text: formatted,
  selection: TextSelection.collapsed(offset: formatted.length),
);
}
}

