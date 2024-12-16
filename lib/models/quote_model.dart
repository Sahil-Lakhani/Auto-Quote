class QuoteItem {
  final String description;
  final String? dimensions;
  final double areaOrQuantity;
  final double unitPrice;
  final double totalPrice;

  QuoteItem({
    required this.description,
    this.dimensions,
    required this.areaOrQuantity,
    required this.unitPrice,
    required this.totalPrice,
  });
}

class QuoteSection {
  final String title;
  final List<QuoteItem> items;

  QuoteSection({
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
  final List<QuoteSection> sections;

  Quote({
    required this.companyName,
    required this.address,
    required this.phone,
    required this.clientName,
    required this.date,
    required this.sections,
  });
}
