class QuoteItem {
  final String description;
  final String? dimensions;
  final int? quantity;
  final double unitPrice;
  final double totalPrice;

  QuoteItem({
    required this.description,
    this.dimensions,
    this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });
}

class QuoteRoomType {
  final String title;
  final List<QuoteItem> items;

  QuoteRoomType({
    required this.title,
    required this.items,
  });
}

class Quote {
  final String companyName;
  final String address;
  final String phone;
  final String clientName;
  final DateTime date;
  final List<QuoteRoomType> sections;

  Quote({
    required this.companyName,
    required this.address,
    required this.phone,
    required this.clientName,
    required this.date,
    required this.sections,
  });
}
