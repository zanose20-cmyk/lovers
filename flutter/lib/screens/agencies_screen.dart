import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/agencies_provider.dart';

class AgenciesScreen extends StatefulWidget {
  const AgenciesScreen({super.key});

  @override
  State<AgenciesScreen> createState() => _AgenciesScreenState();
}

class _AgenciesScreenState extends State<AgenciesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgenciesProvider>().loadAgencies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('الوكالات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/create-agency'),
          ),
        ],
      ),
      body: Consumer<AgenciesProvider>(
        builder: (ctx, ap, _) {
          if (ap.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (ap.agencies.isEmpty) {
            return const Center(child: Text('لا توجد وكالات', style: TextStyle(color: AppColors.textHint)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ap.agencies.length,
            itemBuilder: (context, index) {
              final agency = ap.agencies[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.business, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(agency.name ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                              if (agency.stats != null)
                                Text('${agency.stats!.totalMembers ?? 0} أعضاء', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              if (agency.agencyId != null) {
                                ap.joinAgency(agency.agencyId!);
                              }
                            },
                            child: const Text('انضمام', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    if (agency.description != null && agency.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(agency.description!, style: const TextStyle(color: AppColors.textHint, fontSize: 13)),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
