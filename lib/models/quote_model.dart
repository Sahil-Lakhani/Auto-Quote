import 'dart:typed_data';

class QuoteItem {
  final String description;
  final String? dimensions;
  final int? quantity;
  final double? pricePerSqft;
  final double unitPrice;
  final double totalPrice;

  QuoteItem({
    required this.description,
    this.dimensions,
    this.quantity,
    this.pricePerSqft,
    required this.unitPrice,
    required this.totalPrice,
  });
}

class QuoteRoomType {
  final String title;
  final List<QuoteItem> items;
  final double roomTotal;

  QuoteRoomType({
    required this.title,
    required this.items,
    required this.roomTotal,
  });

  double get total => items.fold(0.0, (sum, item) => sum + item.totalPrice);
}

class Quote {
  final String companyName;
  final String address;
  final Uint8List? logoBytes;
  final String phone;
  final String clientName;
  final DateTime date;
  final List<QuoteRoomType> sections;
  final int transportCharges;
  final int laborCharges;
  final double subtotal;
  final bool isGstEnabled;
  final double cgst;
  final double sgst;
  final double grandTotal;

  Quote({
    required this.companyName,
    required this.address,
    this.logoBytes,
    required this.phone,
    required this.clientName,
    required this.date,
    required this.sections,
    required this.transportCharges,
    required this.laborCharges,
    required this.subtotal,
    required this.isGstEnabled,
    required this.cgst,
    required this.sgst,
    required this.grandTotal,
  });
}
