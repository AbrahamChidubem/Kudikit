import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/presentation/linkdevice/enable_biometrics.dart';
import 'package:kudipay/provider/provider.dart';


class DataSyncScreen extends ConsumerStatefulWidget {
  const DataSyncScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DataSyncScreen> createState() => _DataSyncScreenState();
}

class _DataSyncScreenState extends ConsumerState<DataSyncScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceLinkingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          _buildBody(context, state),
          _buildButton(context, state),
          if (state.isSyncing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF069494),
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF5F9F5),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DeviceLinkingState state) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Title
            Text(
              'Almost done',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 28),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 8)),

            // Subtitle
            Text(
              'Would you like to sync your data to this device? You\ncan always change this later.',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: Colors.black54,
                height: 1.5,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 32)),

            // Sync options
            _buildSyncOption(
              context,
              title: 'Saved Beneficiary',
              subtitle: 'People you frequently send money to',
              value: state.syncSelection.savedBeneficiary,
              onChanged: (value) {
                ref
                    .read(deviceLinkingProvider.notifier)
                    .updateSyncSelection(savedBeneficiary: value);
              },
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            _buildSyncOption(
              context,
              title: 'Recent Transaction',
              subtitle: 'You last 90 days of transaction',
              value: state.syncSelection.recentTransactions,
              onChanged: (value) {
                ref
                    .read(deviceLinkingProvider.notifier)
                    .updateSyncSelection(recentTransactions: value);
              },
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            _buildSyncOption(
              context,
              title: 'App preference',
              subtitle: 'Retaining your previous user settings',
              value: state.syncSelection.appPreferences,
              onChanged: (value) {
                ref
                    .read(deviceLinkingProvider.notifier)
                    .updateSyncSelection(appPreferences: value);
              },
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: value,
            onChanged: (newValue) => onChanged(newValue ?? false),
            activeColor: const Color(0xFF069494),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          SizedBox(width: AppLayout.scaleWidth(context, 12)),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 4)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, DeviceLinkingState state) {
    return Positioned(
      bottom: AppLayout.scaleHeight(context, 40),
      left: AppLayout.scaleWidth(context, 24),
      right: AppLayout.scaleWidth(context, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: AppLayout.scaleHeight(context, 56),
            child: ElevatedButton(
              onPressed: state.isSyncing
                  ? null
                  : () async {
                      await ref.read(deviceLinkingProvider.notifier).syncData();

                      if (mounted && !state.isSyncing) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const EnableBiometricsScreen(),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF069494),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Text(
                'Continue',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 12)),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EnableBiometricsScreen(),
                ),
              );
            },
            child: Text(
              'Skip',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: const Color(0xFF069494),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}