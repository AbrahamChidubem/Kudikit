import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/model/IDdocument/document_data.dart';
import 'package:kudipay/presentation/Identity/confirm_info.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'dart:io';
import 'package:kudipay/provider/provider.dart';


class UploadIdCardScreen extends ConsumerWidget {
  const UploadIdCardScreen({Key? key}) : super(key: key);

  Future<void> _pickDocument(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;
        ref
            .read(documentUploadProvider.notifier)
            .setUploadedFile(file, fileName);
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentData = ref.watch(documentUploadProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: AppLayout.pagePadding(context),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Upload a valid ID card',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 26),
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 8)),
                      Text(
                        'Kindly select the document you want to upload',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 32)),
                      Text(
                        'Select document type',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 8)),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                              AppLayout.scaleWidth(context, 8)),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonFormField<DocumentType>(
                          value: documentData.documentType,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppLayout.scaleWidth(context, 16),
                              vertical: AppLayout.scaleHeight(context, 12),
                            ),
                          ),
                          hint: const Text('Select Document Type'),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: DocumentType.values.map((type) {
                            return DropdownMenuItem<DocumentType>(
                              value: type,
                              child: Text(type.displayName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              ref
                                  .read(documentUploadProvider.notifier)
                                  .setDocumentType(value);
                            }
                          },
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 32)),
                      Text(
                        'Upload Document',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 16)),
                      GestureDetector(
                        onTap: () => _pickDocument(ref),
                        child: Container(
                          width: double.infinity,
                          height: AppLayout.scaleHeight(context, 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                                AppLayout.scaleWidth(context, 12)),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: AppLayout.scaleWidth(context, 48),
                                color: Colors.grey[400],
                              ),
                              SizedBox(
                                  height: AppLayout.scaleHeight(context, 16)),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppLayout.scaleWidth(context, 24),
                                  vertical: AppLayout.scaleHeight(context, 12),
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(
                                      AppLayout.scaleWidth(context, 20)),
                                ),
                                child: Text(
                                  'Upload Document',
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 14),
                                    color: const Color(0xFF069494),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (documentData.fileName != null) ...[
                                SizedBox(
                                    height: AppLayout.scaleHeight(context, 12)),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        AppLayout.scaleWidth(context, 16),
                                  ),
                                  child: Text(
                                    documentData.fileName!,
                                    style: TextStyle(
                                      fontSize: AppLayout.fontSize(context, 12),
                                      color: Colors.black54,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: AppLayout.pagePadding(context),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: documentData.isComplete
                        ? () async {
                            // Show loading
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF069494),
                                ),
                              ),
                            );

                            try {
                              // Update KYC status for document verification
                              await ref
                                  .read(authProvider.notifier)
                                  .updateKycStatus(
                                    isDocumentVerified: true,
                                  );

                              // Get user info from storage
                              final storageService =
                                  ref.read(storageServiceProvider);
                              final userInfo = await storageService.getUserInfo();

                              // Close loading dialog
                              if (context.mounted) {
                                Navigator.pop(context);
                              }

                              if (context.mounted && userInfo != null) {
                                // Navigate to ConfirmInfoScreen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ConfirmInfoScreen(
                                      userInfo: userInfo,
                                    ),
                                  ),
                                );
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User information not found. Please complete your profile.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              // Close loading dialog
                              if (context.mounted) {
                                Navigator.pop(context);
                              }

                              // Show error
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF069494),
                      disabledBackgroundColor: Colors.grey[300],
                      padding: EdgeInsets.symmetric(
                        vertical: AppLayout.scaleHeight(context, 18),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppLayout.scaleWidth(context, 30)),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Next',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 16),
                        fontWeight: FontWeight.w600,
                        color: documentData.isComplete
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}