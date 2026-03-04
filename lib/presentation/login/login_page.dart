import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/bottom_nav.dart';
import 'package:kudipay/formatting/widget/connectivity_widget.dart';
import 'package:kudipay/presentation/linkdevice/link_device_screen.dart';
import 'package:kudipay/presentation/signup/signup.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/services/api_services.dart';
import 'package:kudipay/services/storage_services.dart';

class LoginPage extends ConsumerStatefulWidget {
  final String? email;
  final String? phoneNumber;
  const LoginPage({this.email, this.phoneNumber, super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _passwordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _prefillPhone();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupConnectivityListener());
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _prefillPhone() async {
    if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
      _phoneController.text = widget.phoneNumber!;
      return;
    }
    try {
      final userModel = await StorageService.instance.getUserModel();
      if (userModel != null && userModel.phoneNumber.isNotEmpty) {
        final phone = userModel.phoneNumber;
        _phoneController.text = phone.startsWith('+234') ? '0${phone.substring(4)}' : phone;
      }
    } catch (_) {}
  }

  void _setupConnectivityListener() {
    ref.listen(connectivityProvider, (previous, next) {
      next.whenData((isConnected) {
        if (previous?.value != null && previous!.value! && !isConnected) {
          ConnectivitySnackBar.showNoInternet(context);
        } else if (previous?.value != null && !previous!.value! && isConnected) {
          ConnectivitySnackBar.showConnectionRestored(context);
        }
      });
    });
  }

  Future<void> _handleLogin() async {
    final isConnected = ref.read(currentConnectivityProvider);
    if (!isConnected) { ConnectivitySnackBar.showNoInternet(context); return; }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final password = _passwordController.text.trim();
      final isValid = await StorageService.instance.verifyPin(password);
      if (!mounted) return;
      if (isValid) {
        await ref.read(authProvider.notifier).login(
          email: widget.email ?? ref.read(userEmailProvider),
          password: password,
        );
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BottomNavBar()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Incorrect password. Please try again.'),
          backgroundColor: Colors.red,
        ));
        _passwordController.clear();
      }
    } on NoInternetException {
      if (mounted) ConnectivitySnackBar.showNoInternet(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Login failed: ${e.toString()}'), backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectivityState = ref.watch(connectivityStateProvider);
    final isOnline = connectivityState.isConnected;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF7F2),
      body: SafeArea(
        child: Column(
          children: [
            if (!isOnline) _buildOfflineBanner(context),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppLayout.scaleWidth(context, 24)),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: AppLayout.scaleHeight(context, 16)),
                        _buildTopBar(context, isOnline),
                        SizedBox(height: AppLayout.scaleHeight(context, 48)),
                        Text('Login into your\nKudikit Account',
                          style: TextStyle(fontSize: AppLayout.fontSize(context, 27), fontWeight: FontWeight.w700, color: Colors.black87, height: 1.2)),
                        SizedBox(height: AppLayout.scaleHeight(context, 32)),
                        _buildPhoneField(context, isOnline),
                        SizedBox(height: AppLayout.scaleHeight(context, 12)),
                        _buildPasswordField(context, isOnline),
                        SizedBox(height: AppLayout.scaleHeight(context, 4)),
                        Align(alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isOnline ? _handleForgotPin : null,
                            child: Text('Forgot PIN', style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 13),
                              fontWeight: FontWeight.w600,
                              color: isOnline ? const Color(0xFF5C7C6F) : Colors.grey,
                            )),
                          )),
                        SizedBox(height: AppLayout.scaleHeight(context, 20)),
                        _buildContinueButton(context, isOnline),
                        SizedBox(height: AppLayout.scaleHeight(context, 20)),
                        _buildSignUpRow(context, isOnline),
                        SizedBox(height: AppLayout.scaleHeight(context, 40)),
                        _buildLicensingFooter(context),
                        SizedBox(height: AppLayout.scaleHeight(context, 20)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isOnline) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: AppLayout.scaleWidth(context, 36),
          height: AppLayout.scaleWidth(context, 36),
          child: Image.asset('assets/images/kudikit_logo.png', fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => CustomPaint(painter: _KudiKitLogoPainter())),
        ),
        TextButton(
          onPressed: isOnline
              ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LinkDeviceScreen()))
              : () => ConnectivitySnackBar.showNoInternet(context),
          child: Text('Link new device', style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14), fontWeight: FontWeight.w500,
            color: isOnline ? const Color(0xFF069494) : Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildPhoneField(BuildContext context, bool isOnline) {
    return Container(
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        enabled: !_isLoading && isOnline,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(fontSize: AppLayout.fontSize(context, 16), fontWeight: FontWeight.w500, color: Colors.black87),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: AppLayout.scaleWidth(context, 14), right: AppLayout.scaleWidth(context, 10)),
            child: Icon(Icons.person_outline, color: Colors.grey[500], size: AppLayout.scaleWidth(context, 22))),
          prefixIconConstraints: const BoxConstraints(),
          suffixIcon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500], size: AppLayout.scaleWidth(context, 22)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: AppLayout.scaleWidth(context, 16), vertical: AppLayout.scaleHeight(context, 16)),
          hintText: 'Phone number',
          hintStyle: TextStyle(fontSize: AppLayout.fontSize(context, 15), color: Colors.grey[400]),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your phone number' : null,
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context, bool isOnline) {
    return Container(
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: TextFormField(
        controller: _passwordController,
        obscureText: !_passwordVisible,
        enabled: !_isLoading && isOnline,
        style: TextStyle(fontSize: AppLayout.fontSize(context, 16), fontWeight: FontWeight.w500, color: Colors.black87),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: AppLayout.scaleWidth(context, 14), right: AppLayout.scaleWidth(context, 10)),
            child: Icon(Icons.lock_outline, color: Colors.grey[500], size: AppLayout.scaleWidth(context, 22))),
          prefixIconConstraints: const BoxConstraints(),
          suffixIcon: IconButton(
            icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey[500], size: AppLayout.scaleWidth(context, 22)),
            onPressed: () => setState(() => _passwordVisible = !_passwordVisible)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: AppLayout.scaleWidth(context, 16), vertical: AppLayout.scaleHeight(context, 16)),
          hintText: 'Password',
          hintStyle: TextStyle(fontSize: AppLayout.fontSize(context, 15), color: Colors.grey[400]),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your password' : null,
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context, bool isOnline) {
    return SizedBox(
      width: double.infinity, height: AppLayout.scaleHeight(context, 56),
      child: ElevatedButton(
        onPressed: (_isLoading || !isOnline) ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8EC8A5),
          disabledBackgroundColor: const Color(0xFF8EC8A5).withOpacity(0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 28))),
          elevation: 0),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(isOnline ? 'Continue' : 'No Internet Connection', style: TextStyle(
                fontSize: AppLayout.fontSize(context, 17), fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }

  Widget _buildSignUpRow(BuildContext context, bool isOnline) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Already have an account? ', style: TextStyle(fontSize: AppLayout.fontSize(context, 14), color: Colors.black54)),
      TextButton(
        onPressed: isOnline ? () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignUpScreen())) : null,
        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        child: Text('Log in', style: TextStyle(
          fontSize: AppLayout.fontSize(context, 14), fontWeight: FontWeight.w700,
          color: isOnline ? const Color(0xFF069494) : Colors.grey)),
      ),
    ]);
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.red.shade700,
      child: Row(children: [
        const Icon(Icons.wifi_off, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        const Expanded(child: Text('No internet — Login requires a connection', style: TextStyle(color: Colors.white, fontSize: 13))),
        TextButton(onPressed: () => ref.read(connectivityStateProvider.notifier).refresh(),
          child: const Text('Retry', style: TextStyle(color: Colors.white))),
      ]),
    );
  }

  Widget _buildLicensingFooter(BuildContext context) {
    return Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: 4, children: [
      Container(width: 24, height: 24, padding: const EdgeInsets.all(2),
        child: Image.asset('assets/images/cbn.png', fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.account_balance, size: 16, color: Color(0xFF2C2C2C)))),
      const Text('Licensed by the ', style: TextStyle(color: Colors.black54, fontSize: 11)),
      const Text('CBN', style: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)),
      const Text(' and insured by the', style: TextStyle(color: Colors.black54, fontSize: 11)),
      Container(height: 20, padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Image.asset('assets/images/ndicc.png', fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.account_balance, size: 16, color: Color(0xFF2C2C2C)))),
    ]);
  }

  void _handleForgotPin() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _ForgotPinSheet());
  }
}

class _ForgotPinSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.all(24),
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),
        Container(width: 64, height: 64,
          decoration: BoxDecoration(color: const Color(0xFF069494).withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.lock_reset, color: Color(0xFF069494), size: 32)),
        const SizedBox(height: 16),
        const Text('Forgot PIN?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Text('To reset your PIN, log in using your email and create a new one, or contact our support team.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: () { Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN reset coming soon'), backgroundColor: Color(0xFF069494))); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF069494),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), elevation: 0),
            child: const Text('Reset via Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)))),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 52,
          child: OutlinedButton(onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF069494)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
            child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF069494))))),
      ])),
    );
  }
}

class _KudiKitLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF069494)..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final w = size.width; final h = size.height;
    canvas.drawPath(Path()..moveTo(w*0.18,h*0.2)..lineTo(w*0.42,h*0.5)..lineTo(w*0.18,h*0.8), paint);
    canvas.drawPath(Path()..moveTo(w*0.42,h*0.2)..lineTo(w*0.66,h*0.5)..lineTo(w*0.42,h*0.8), paint);
  }
  @override bool shouldRepaint(_) => false;
}