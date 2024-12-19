import 'package:auto_quote/models/quote_model.dart';
import 'package:flutter/material.dart';

class QuoteFormProvider extends ChangeNotifier {
  String companyName = '';
  String address = '';
  String phone = '';
  String customerName = '';
  String date = '';
  List<QuoteRoomType> rooms = [];
  Map<int, int> itemQuantities = {};

  void updateCompanyName(String value) {
    companyName = value;
    notifyListeners();
  }

  void updateAddress(String value) {
    address = value;
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

  void updateDate(String value) {
    date = value;
    notifyListeners();
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
    phone = '';
    customerName = '';
    date = '';
    rooms.clear();
    itemQuantities.clear();
    notifyListeners();
  }
}
