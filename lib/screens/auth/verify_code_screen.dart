import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class VerifyCodeScreen extends StatefulWidget {
  final bool isSmsVerification;
  const VerifyCodeScreen({this.isSmsVerification = false});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final List<TextEditingController> _controllers =
  List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());

  String get enteredCode => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Code')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is CodeVerificationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verification successful!')),
            );
            context.go('/home');
          } else if (state is CodeVerificationFailure ||
              state is AuthFailure) {
            final msg = (state is CodeVerificationFailure)
                ? state.error
                : (state as AuthFailure).error;
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg)));
          }
        },
        builder: (context, state) {
          final isVerifying = state is CodeVerificationInProgress;
          final isResending = state is ResendCodeInProgress;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (i) => _buildBox(i)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: (enteredCode.length == 5 && !isVerifying)
                      ? () {
                    context.read<AuthBloc>().add(VerifyCodeEvent(
                      code: enteredCode,
                      isSms: widget.isSmsVerification,
                      email: widget.isSmsVerification ? null : '',
                    ));
                  }
                      : null,
                  child: isVerifying
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Continue'),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(isResending ? 'Sending…' : 'Resend code'),
                  onPressed: isResending
                      ? null
                      : () => context.read<AuthBloc>().add(
                    ResendCodeEvent(
                      contact: '', // could store last contact if needed
                      isSms: widget.isSmsVerification,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBox(int idx) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: _controllers[idx],
        focusNode: _focusNodes[idx],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: const InputDecoration(counterText: ''),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (val) {
          if (val.isNotEmpty && idx < 4) {
            FocusScope.of(context).requestFocus(_focusNodes[idx + 1]);
          } else if (val.isEmpty && idx > 0) {
            FocusScope.of(context).requestFocus(_focusNodes[idx - 1]);
          }
          setState(() {});
        },
      ),
    );
  }
}