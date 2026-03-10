import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/presentation/transfer/single_transfer/transfer_success_dialogue.dart';
import 'package:kudipay/provider/provider.dart';

class PinEntryBottomSheet extends ConsumerStatefulWidget {
  const PinEntryBottomSheet({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PinEntryBottomSheet(),
    );
  }

  @override
  ConsumerState<PinEntryBottomSheet> createState() =>
      _PinEntryBottomSheetState();
}

class _PinEntryBottomSheetState extends ConsumerState<PinEntryBottomSheet> {
  String _pin = '';
  final int _pinLength = 6;

  void _onNumberPressed(String number) {
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += number;
      });

      // Auto-submit when PIN is complete
      if (_pin.length == _pinLength) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _submitPin();
        });
      }
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _submitPin() async {
    await ref.read(p2pTransferProvider.notifier).processTransfer(_pin);
    if (mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const TransactionSuccessBottomSheet()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(p2pTransferProvider);

    return Container(
      decoration: const BoxDecoration(
        color:  Color(0xFFF9F9F9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppLayout.scaleWidth(context, 24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Enter Transaction PIN',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 32)),

              // PIN dots
              _buildPinDots(context),

              SizedBox(height: AppLayout.scaleHeight(context, 40)),

              // Numeric keypad
              _buildKeypad(context),

              SizedBox(height: AppLayout.scaleHeight(context, 16)),

              // Loading indicator
              if (state.isProcessingTransfer)
                Padding(
                  padding: EdgeInsets.only(
                    top: AppLayout.scaleHeight(context, 16),
                  ),
                  child: const CircularProgressIndicator(
                    color: Color(0xFF069494),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        final isFilled = index < _pin.length;
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 6),
          ),
          width: AppLayout.scaleWidth(context, 12),
          height: AppLayout.scaleWidth(context, 12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? const Color(0xFF069494) : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildKeypad(BuildContext context) {
    return Column(
      children: [
        _buildKeypadRow(context, ['1', '2', '3']),
        SizedBox(height: AppLayout.scaleHeight(context, 16)),
        _buildKeypadRow(context, ['4', '5', '6']),
        SizedBox(height: AppLayout.scaleHeight(context, 16)),
        _buildKeypadRow(context, ['7', '8', '9']),
        SizedBox(height: AppLayout.scaleHeight(context, 16)),
        _buildKeypadRow(context, ['', '0', 'delete']),
      ],
    );
  }

  Widget _buildKeypadRow(BuildContext context, List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) {
        if (number.isEmpty) {
          return SizedBox(width: AppLayout.scaleWidth(context, 70));
        }

        if (number == 'delete') {
          return _buildKeypadButton(
            context,
            child: Icon(
              Icons.backspace_outlined,
              color: const Color(0xFF069494),
              size: AppLayout.scaleWidth(context, 24),
            ),
            onPressed: _onDeletePressed,
          );
        }

        return _buildKeypadButton(
          context,
          child: Text(
            number,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 24),
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          onPressed: () => _onNumberPressed(number),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton(
    BuildContext context, {
    required Widget child,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: AppLayout.scaleWidth(context, 70),
        height: AppLayout.scaleWidth(context, 70),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
