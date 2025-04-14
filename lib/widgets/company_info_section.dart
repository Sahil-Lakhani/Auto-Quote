import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quote_form_provider.dart';

class CompanyInfoSection extends StatelessWidget {
  final TextEditingController companyController;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final Function() pickLogo;
  final bool isReadOnly;

  const CompanyInfoSection({
    super.key,
    required this.companyController,
    required this.addressController,
    required this.phoneController,
    required this.pickLogo,
    this.isReadOnly = false,
  });

  Widget _buildLogoPreview(BuildContext context) {
    return Consumer<QuoteFormProvider>(
      builder: (context, provider, child) {
        return Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: isReadOnly && provider.logoFile == null
                ? Colors.grey[100]
                : null,
          ),
          child: provider.logoFile != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.file(
                            provider.logoFile!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    if (!isReadOnly)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => provider.removeLogo(),
                          ),
                        ),
                      ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isReadOnly
                            ? Icons.photo_outlined
                            : Icons.add_photo_alternate_outlined,
                        size: 32,
                        color: Colors.grey[600],
                      ),
                      if (!isReadOnly)
                        TextButton(
                          onPressed: pickLogo,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('Choose File'),
                        ),
                      if (isReadOnly)
                        Text(
                          'No company logo',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isReadOnly ? Colors.grey[50] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Company Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isReadOnly)
                  Text(
                    'Cannot be edited',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLogoPreview(context),
            const SizedBox(height: 16),
            TextField(
              controller: companyController,
              decoration: InputDecoration(
                labelText: 'Company Name',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.business),
                filled: isReadOnly,
                fillColor: isReadOnly ? Colors.grey[200] : null,
              ),
              readOnly: isReadOnly,
              enabled: !isReadOnly,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on),
                filled: isReadOnly,
                fillColor: isReadOnly ? Colors.grey[200] : null,
              ),
              maxLines: 2,
              readOnly: isReadOnly,
              enabled: !isReadOnly,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Phone',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone),
                filled: isReadOnly,
                fillColor: isReadOnly ? Colors.grey[200] : null,
              ),
              keyboardType: TextInputType.phone,
              readOnly: isReadOnly,
              enabled: !isReadOnly,
            ),
          ],
        ),
      ),
    );
  }
}
