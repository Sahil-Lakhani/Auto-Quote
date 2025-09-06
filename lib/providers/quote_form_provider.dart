import 'dart:io';

import 'package:auto_quote/models/company_model.dart';
import 'package:auto_quote/models/quote_model.dart';
import 'package:flutter/material.dart';

class QuoteFormProvider extends ChangeNotifier {
  String companyName = '';
  String address = '';
  File? _logoFile;
  String phone = '';
  String customerName = '';
  String customerPhone = '';
  String date = '';
  String notes = '';
  List<QuoteRoomType> rooms = [];
  Map<int, int> itemQuantities = {};
  int transportCharges = 0;
  int laborCharges = 0;
  int? _advancePaymentPercentage = 50;
  bool _isAdvancePaymentEnabled = true;
  bool _isNotesSectionEnable = true;
  bool _isGstEnabled = false;
  String? _selectedCompanyId;
  Company? _selectedCompany;

  bool get isGstEnabled => _isGstEnabled;
  bool get isAdvancePaymentEnabled => _isAdvancePaymentEnabled;
  int? get advancePaymentPercentage =>
      _isAdvancePaymentEnabled ? _advancePaymentPercentage : null;

  bool get isNotesSectionEnable => _isNotesSectionEnable;
  String? get selectedCompanyId => _selectedCompanyId;
  Company? get selectedCompany => _selectedCompany;
  bool get hasSelectedCompany => _selectedCompany != null;
  bool get hasLogo => _logoFile != null;
  // bool get isCompanyInfoComplete => hasSelectedCompany && hasLogo;

  void toggleGst(bool value) {
    _isGstEnabled = value;
    notifyListeners();
  }

  void toggleAdvancePayment(bool value) {
    _isAdvancePaymentEnabled = value;
    if (!value) _advancePaymentPercentage = 0;
    notifyListeners();
  }

  void toggleNotesSection(bool value) {
    // This method can be used to show/hide notes section if needed
    _isNotesSectionEnable = value;
    if (!value) notes = '';
    notifyListeners();
  }

  void selectCompany(Company? company) {
    _selectedCompany = company;
    _selectedCompanyId = company?.id;
    if (company != null) {
      companyName = company.name;
      address = company.address;
      phone = company.phone;
    }
    notifyListeners();
  }

  void clearCompanySelection() {
    _selectedCompany = null;
    _selectedCompanyId = null;
    companyName = '';
    address = '';
    phone = '';
    _logoFile = null;
    notifyListeners();
  }

  // Calculate room total (excluding transport and labor)
  double get roomTotal => rooms.fold(
      0.0,
      (sum, room) =>
          sum +
          room.items.fold(0.0, (itemSum, item) => itemSum + item.totalPrice));

  // Calculate subtotal (including transport and labor, before GST)
  double get subtotal => roomTotal + transportCharges + laborCharges;

  // Calculate GST components based on room total only
  double get cgst => roomTotal * 0.09;
  double get sgst => roomTotal * 0.09;

  // Calculate grand total (room total with GST + transport + labor)
  double get grandTotal {
    if (_isGstEnabled) {
      return subtotal + cgst + sgst;
    } else {
      return subtotal;
    }
  }

  File? get logoFile => _logoFile;
  void updateCompanyName(String value) {
    companyName = value;
    notifyListeners();
  }

  void updateAddress(String value) {
    address = value;
    notifyListeners();
  }

  void updateLogo(File? file) {
    _logoFile = file;
    notifyListeners();
  }

  // Add method to remove logo
  void removeLogo() {
    _logoFile = null;
    notifyListeners();
  }

  void updatePhone(String value) {
    phone = value;
    notifyListeners();
  }

  void updateCustomerName(String value) {
    customerName = value;
    notifyListeners();
  }

  void updateCustomerPhone(String value) {
    customerPhone = value;
    notifyListeners();
  }

  void updateDate(String value) {
    date = value;
    notifyListeners();
  }

  void updateTransportCharges(String value) {
    try {
      transportCharges = int.tryParse(value) ?? 0; // Changed to int.tryParse
      notifyListeners();
    } catch (e) {
      transportCharges = 0;
      notifyListeners();
    }
  }

  void updateLaborCharges(String value) {
    try {
      laborCharges = int.tryParse(value) ?? 0; // Changed to int.tryParse
      notifyListeners();
    } catch (e) {
      laborCharges = 0;
      notifyListeners();
    }
  }

  void updateAdvancePaymentPercentage(String value) {
    if (!_isAdvancePaymentEnabled) return;
    try {
      _advancePaymentPercentage = int.tryParse(value);
      notifyListeners();
    } catch (e) {
      _advancePaymentPercentage = 50;
      notifyListeners();
    }
  }

  double get advancePaymentAmount {
    if (_advancePaymentPercentage == null) return 0.0;
    return (grandTotal * _advancePaymentPercentage!) / 100;
  }

  void addRoom(QuoteRoomType room) {
    rooms.add(room);
    notifyListeners();
  }

  void removeRoom(int index) {
    rooms.removeAt(index);
    notifyListeners();
  }

  void addItemToRoom(int roomIndex, QuoteItem item) {
    rooms[roomIndex].items.add(item);
    notifyListeners();
  }

  void removeItemFromRoom(int roomIndex, int itemIndex) {
    rooms[roomIndex].items.removeAt(itemIndex);
    notifyListeners();
  }

  void updateItemQuantity(int index, int quantity) {
    itemQuantities[index] = quantity;
    notifyListeners();
  }

  void updateNotes(String value) {
    notes = value;
    notifyListeners();
  }

  void clearForm() {
    companyName = '';
    address = '';
    _logoFile = null;
    phone = '';
    customerName = '';
    date = '';
    notes = '';
    rooms.clear();
    itemQuantities.clear();
    transportCharges = 0;
    laborCharges = 0;
    _advancePaymentPercentage = null;
    notifyListeners();
  }
}
