import 'api_service.dart';

class WalletService {
  final ApiService api;
  WalletService(this.api);

  Future<List<dynamic>> getTransactions() async {
    final resp = await api.get('/api/wallet/transactions');
    if (resp.statusCode == 200) {
      final data = resp.data;
      if (data is List) return data as List<dynamic>;
      if (data['transactions'] is List) return (data['transactions'] as List<dynamic>);
      if (data['data'] is List) return (data['data'] as List<dynamic>);
    }
    return [];
  }

  Future<bool> recharge(int amount) async {
    final resp = await api.post('/api/wallet/recharge', body: {'amountCoins': amount});
    return resp.statusCode == 200 && resp.data['ok'] == true;
  }

  Future<bool> withdraw(int amount) async {
    final resp = await api.post('/api/wallet/withdraw', body: {'amountCoins': amount});
    return resp.statusCode == 200 && resp.data['ok'] == true;
  }
}
