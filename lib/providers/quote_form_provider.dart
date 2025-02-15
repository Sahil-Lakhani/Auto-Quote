import 'dart:io';

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
  List<QuoteRoomType> rooms = [];
  Map<int, int> itemQuantities = {};
  int transportCharges = 0;
  int laborCharges = 0;

  bool _isGstEnabled = false; 

  bool get isGstEnabled => _isGstEnabled;

  void toggleGst(bool value) {
    _isGstEnabled = value;
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

  void clearForm() {
    companyName = '';
    address = '';
    _logoFile = null;
    phone = '';
    customerName = '';
    date = '';
    rooms.clear();
    itemQuantities.clear();
    transportCharges = 0;
    laborCharges = 0;
    notifyListeners();
  }
}
