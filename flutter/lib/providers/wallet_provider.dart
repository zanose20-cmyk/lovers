import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../services/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _service;
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;
  int _balance = 0;

  WalletProvider(ApiService api) : _service = WalletService(api);

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get balance => _balance;

  void setBalance(int bal) {
    _balance = bal;
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getTransactions();
      _transactions = data.map((e) => TransactionModel.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> recharge(int amount) async {
    try {
      final ok = await _service.recharge(amount);
      if (ok) {
        _balance += amount;
        notifyListeners();
      }
      return ok;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> withdraw(int amount) async {
    try {
      final ok = await _service.withdraw(amount);
      if (ok) {
        _balance -= amount;
        notifyListeners();
      }
      return ok;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
