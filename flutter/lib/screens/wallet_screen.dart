import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/wallet_provider.dart';
import '../models/transaction_model.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('المحفظة')),
      body: Consumer<WalletProvider>(
        builder: (ctx, wp, _) {
          if (wp.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.premiumGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)],
                  ),
                  child: Column(
                    children: [
                      const Text('الرصيد الإجمالي', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text('${wp.balance}', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      const Text('عملة', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showRechargeDialog(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                                child: const Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add, color: Colors.white, size: 20), SizedBox(width: 4), Text('شحن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))])),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showWithdrawDialog(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                                child: const Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.download, color: Colors.white, size: 20), SizedBox(width: 4), Text('سحب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))])),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('المعاملات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                if (wp.transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('لا توجد معاملات بعد', style: TextStyle(color: AppColors.textHint)),
                  )
                else
                  ...wp.transactions.map((tx) => _TransactionItem(tx: tx)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRechargeDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('شحن الرصيد', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'المبلغ',
            hintStyle: TextStyle(color: AppColors.textHint),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textHint)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(onPressed: () { controller.dispose(); Navigator.pop(ctx); }, child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                try {
                  final ok = await context.read<WalletProvider>().recharge(amount);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? 'تم الشحن بنجاح' : 'فشل الشحن')),
                    );
                  }
                } catch (_) {
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              }
              controller.dispose();
            },
            child: const Text('شحن', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('سحب الرصيد', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'المبلغ',
            hintStyle: TextStyle(color: AppColors.textHint),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textHint)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(onPressed: () { controller.dispose(); Navigator.pop(ctx); }, child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                try {
                  final ok = await context.read<WalletProvider>().withdraw(amount);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? 'تم السحب بنجاح' : 'فشل السحب')),
                    );
                  }
                } catch (_) {
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              }
              controller.dispose();
            },
            child: const Text('سحب', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final TransactionModel tx;
  const _TransactionItem({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isReceived = tx.type == 'gift_received' || tx.type == 'recharge';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.backgroundCard, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: (isReceived ? AppColors.success : AppColors.error).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(isReceived ? Icons.arrow_downward : Icons.arrow_upward, color: isReceived ? AppColors.success : AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_txLabel(), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(_timeAgo(), style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
              ],
            ),
          ),
          Text('${isReceived ? '+' : '-'}${tx.amountCoins ?? 0}', style: TextStyle(color: isReceived ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  String _txLabel() {
    switch (tx.type) {
      case 'recharge': return 'شحن رصيد';
      case 'withdraw': return 'سحب رصيد';
      case 'gift_sent': return 'إرسال هدية';
      case 'gift_received': return 'هدية واردة';
      case 'transfer': return 'تحويل';
      default: return 'معاملة';
    }
  }

  String _timeAgo() {
    if (tx.createdAt == null) return '';
    final diff = DateTime.now().difference(tx.createdAt!);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${tx.createdAt!.day}/${tx.createdAt!.month}/${tx.createdAt!.year}';
  }
}
