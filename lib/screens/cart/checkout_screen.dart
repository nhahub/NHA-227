import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
const CheckoutScreen({Key? key}) : super(key: key);

@override
State createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State {
static const brandBlue = Color(0xFF0E5AA6);

String _method = 'card'; // 'card' | 'paypal'
final  _formKey = GlobalKey<FormState>();
final _holderCtrl = TextEditingController();
final _numberCtrl = TextEditingController();
final _expCtrl = TextEditingController();
final _cvvCtrl = TextEditingController();
bool _saveForFuture = false;

@override
void dispose() {
_holderCtrl.dispose();
_numberCtrl.dispose();
_expCtrl.dispose();
_cvvCtrl.dispose();
super.dispose();
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
// Payment options
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
              // Form
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
                          (_method == 'card' && (v == null || v.trim().isEmpty))
                              ? 'Required'
                              : null,
                    ),
                    const SizedBox(height: 14),

                    const _FieldLabel('Card Number'),
                    _Input(
                      controller: _numberCtrl,
                      hint: '0000 0000 0000 0000',
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (_method == 'card' && (v == null || v.trim().length < 12))
                              ? 'Enter a valid number'
                              : null,
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
                                hint: '--/--',
                                keyboardType: TextInputType.datetime,
                                validator: (v) =>
                                    (_method == 'card' && (v == null || v.isEmpty))
                                        ? 'Required'
                                        : null,
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
                                hint: '...',
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    (_method == 'card' && (v == null || v.length < 3))
                                        ? 'Invalid'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Checkbox(
                          value: _saveForFuture,
                          onChanged: (v) =>
                              setState(() => _saveForFuture = v ?? false),
                          activeColor: brandBlue,
                        ),
                        const Expanded(
                          child: Text('Save Card Securely For Future Payments'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).maybePop(),
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              if (_method == 'paypal') {
                                Navigator.pop(context, {
                                  'method': 'paypal',
                                  'saveForFuture': _saveForFuture,
                                });
                                return;
                              }
                              if (_formKey.currentState?.validate() != true) {
                                return;
                              }
                              Navigator.pop(context, {
                                'method': 'card',
                                'holder': _holderCtrl.text.trim(),
                                'number': _numberCtrl.text.trim(),
                                'exp': _expCtrl.text.trim(),
                                'cvv': _cvvCtrl.text.trim(),
                                'saveForFuture': _saveForFuture,
                              });
                            },
                            child: const Text('Add Card'),
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
      ],
    ),
  ),
);
}
}

// Header (logo + back chevron + title under it)
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
SizedBox(
height: 64,
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
Image.asset(
'assets/images/logo_medlink.png',
height: 40,
fit: BoxFit.contain,
),
],
),
),
const SizedBox(height: 4),
Text(
title,
style: const TextStyle(
fontSize: 22,
fontWeight: FontWeight.w800,
color: Colors.black87,
),
),
const SizedBox(height: 8),
],
),
);
}
}

// Payment method tile with ring selector
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
style:
const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

const _Input({
Key? key,
required this.controller,
required this.hint,
this.keyboardType,
this.validator,
}) : super(key: key);

@override
Widget build(BuildContext context) {
return TextFormField(
controller: controller,
keyboardType: keyboardType,
validator: validator,
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