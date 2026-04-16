import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/model/transfer/bulk_transfer_model.dart';
import 'package:kudipay/presentation/transfer/bulk_transfer/bulk_transfer_file_validation_screen.dart';

class BulkTransferUploadFileScreen extends ConsumerStatefulWidget {
  const BulkTransferUploadFileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BulkTransferUploadFileScreen> createState() =>
      _BulkTransferUploadFileScreenState();
}

class _BulkTransferUploadFileScreenState
    extends ConsumerState<BulkTransferUploadFileScreen> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upload File',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
            child: Center(
              child: Stack(
                children: [
                  SizedBox(
                    width: AppLayout.scaleWidth(context, 30),
                    height: AppLayout.scaleWidth(context, 30),
                    child: CircularProgressIndicator(
                      value: 0.36,
                      strokeWidth: AppLayout.scaleWidth(context, 2),
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF069494)),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        '36%',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 12),
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Upload Area
            GestureDetector(
              onTap: _isUploading ? null : () => _pickFile(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: AppLayout.scaleHeight(context, 48),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF069494),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: AppLayout.scaleWidth(context, 64),
                      height: AppLayout.scaleWidth(context, 64),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.upload_outlined,
                        color: const Color(0xFF069494),
                        size: AppLayout.scaleWidth(context, 32),
                      ),
                    ),
                    SizedBox(height: AppLayout.scaleHeight(context, 16)),
                    Text(
                      _isUploading ? 'Processing...' : 'Tap to upload',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 16),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: AppLayout.scaleHeight(context, 8)),
                    Text(
                      'Support formats: CSV, Excel (.xlsx, xls)',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 13),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Info Box
            Container(
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFF1976D2),
                        size: AppLayout.scaleWidth(context, 20),
                      ),
                      SizedBox(width: AppLayout.scaleWidth(context, 12)),
                      Text(
                        'Don\'t have a file ready?',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 8)),
                  Text(
                    'Download our template and fill in your recipient details',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: const Color(0xFF0D47A1),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 12)),
                  TextButton(
                    onPressed: () => _downloadTemplate(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Download CSV Template here',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 14),
                        color: const Color(0xFF1976D2),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // File Format Requirements
            Container(
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File Format Requirements',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 15),
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 16)),
                  _buildRequirement(
                    context,
                    'Include columns: Name, Account Type, Phone/Account, Bank Name, Amount',
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 12)),
                  _buildRequirement(
                    context,
                    'Account Type should be "Kudikit" or "Bank"',
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 12)),
                  _buildRequirement(
                    context,
                    'Maximum 15 recipients per file',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          color: const Color(0xFF069494),
          size: AppLayout.scaleWidth(context, 18),
        ),
        SizedBox(width: AppLayout.scaleWidth(context, 12)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 13),
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      setState(() {
        _isUploading = true;
      });

      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        // Process the file
        await _processFile(context, file, fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _processFile(
    BuildContext context,
    File file,
    String fileName,
  ) async {
    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF069494),
            ),
          ),
        );
      }

      final fileContent = await file.readAsString();

      // ✅ NEW CSV PARSER (v8)
      final csv = Csv(
        dynamicTyping: true, // converts numbers automatically
      );

      // ✅ Use headers (VERY IMPORTANT)
      final rows = csv.decodeWithHeaders(fileContent);

      final result = _parseRecipientsWithHeaders(rows, fileName);

      if (mounted) Navigator.pop(context);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BulkTransferFileValidationScreen(
              fileName: fileName,
              recipients: result.validRecipients,
              errors: result.errors,
              totalRecipients: rows.length,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  ParseResult _parseRecipientsWithHeaders(
    List<dynamic> rows,
    String fileName,
  ) {
    List<BulkTransferRecipient> validRecipients = [];
    List<FileError> errors = [];

    if (rows.isEmpty) {
      errors.add(FileError(
        row: 0,
        field: 'File',
        message: 'File is empty',
      ));
      return ParseResult(validRecipients, errors);
    }

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];

      try {
        final name = (row['Name'] ?? '').toString().trim();
        final accountType =
            (row['Account Type'] ?? '').toString().trim().toLowerCase();
        final accountNumber = (row['Phone/Account'] ?? '').toString().trim();
        final bankName = (row['Bank Name'] ?? '').toString().trim();
        final amount = row['Amount'] is num
            ? (row['Amount'] as num).toDouble()
            : double.tryParse(row['Amount']?.toString() ?? '');

        // ✅ VALIDATIONS

        if (name.isEmpty) {
          errors.add(FileError(
            row: i + 2, // +2 because header is row 1
            field: 'Name',
            message: 'Name is required',
          ));
        }

        if (accountType != 'kudikit' && accountType != 'bank') {
          errors.add(FileError(
            row: i + 2,
            field: 'Account Type',
            message: 'Must be "Kudikit" or "Bank"',
          ));
        }

        if (accountNumber.isEmpty) {
          errors.add(FileError(
            row: i + 2,
            field: 'Phone/Account',
            message: 'Account/Phone is required',
          ));
        }

        if (accountType == 'bank' && bankName.isEmpty) {
          errors.add(FileError(
            row: i + 2,
            field: 'Bank Name',
            message: 'Bank name is required for bank transfers',
          ));
        }

        if (amount == null || amount <= 0) {
          errors.add(FileError(
            row: i + 2,
            field: 'Amount',
            message: 'Valid amount is required',
          ));
        }

        // ✅ ONLY ADD VALID ROWS
        if (!errors.any((e) => e.row == i + 2)) {
          validRecipients.add(
            BulkTransferRecipient(
              id: DateTime.now().millisecondsSinceEpoch.toString() +
                  i.toString(),
              name: name,
              accountType: accountType == 'kudikit'
                  ? TransferAccountType.kudikit
                  : TransferAccountType.bank,
              accountNumber: accountNumber,
              phoneNumber: accountType == 'kudikit' ? accountNumber : null,
              bankName: accountType == 'bank' ? bankName : null,
              amount: amount,
              isVerified: true,
            ),
          );
        }
      } catch (e) {
        errors.add(FileError(
          row: i + 2,
          field: 'Row',
          message: 'Error parsing row: $e',
        ));
      }
    }

    return ParseResult(validRecipients, errors);
  }

  void _downloadTemplate(BuildContext context) {
    const template = 'Name,Account Type,Phone/Account,Bank Name,Amount\n'
        'John Doe,Kudikit,08012345678,,5000\n'
        'Jane Smith,Bank,0123456789,GTBank,10000\n';

    Clipboard.setData(const ClipboardData(text: template));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'CSV template copied to clipboard — paste into Excel or Sheets',
        ),
        backgroundColor: const Color(0xFF069494),
      ),
    );
  }
}

class ParseResult {
  final List<BulkTransferRecipient> validRecipients;
  final List<FileError> errors;

  ParseResult(this.validRecipients, this.errors);
}

class FileError {
  final int row;
  final String field;
  final String message;

  FileError({
    required this.row,
    required this.field,
    required this.message,
  });
}
