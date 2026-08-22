import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../data/repositories/freelancer_repository.dart';

class BrowseEventsScreen extends ConsumerStatefulWidget {
  const BrowseEventsScreen({super.key});

  @override
  ConsumerState<BrowseEventsScreen> createState() => _BrowseEventsScreenState();
}

class _BrowseEventsScreenState extends ConsumerState<BrowseEventsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final eventState = ref.watch(eventsProvider);
    final freelancerState = ref.watch(freelancerProvider);

    final user = authState.currentUser;
    final events = eventState.events;
    final myApps = freelancerState.myApplications;

    if (user == null) return const SizedBox.shrink();

    final filtered = events.where((e) {
      final matchesSearch = e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.city.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.venue.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _selectedCategory == 'All' || e.type == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Browse Available Events',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Discover verified live production events in your city and submit immediate applications.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: const InputDecoration(
                          hintText: 'Search events by name, city, or venue...',
                          prefixIcon: Icon(LucideIcons.search, size: 16),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _selectedCategory,
                      underline: const SizedBox.shrink(),
                      dropdownColor: AppColors.bgSurface,
                      items: ['All', 'Conference', 'Concert', 'Corporate Summit', 'Exhibition']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                    ),
                  ],
                ),
              ),
            ),
            filtered.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(LucideIcons.calendarX, size: 48, color: AppColors.textMuted),
                            SizedBox(height: 16),
                            Text(
                              'No Events Available',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'No production events found matching your filter in Supabase.',
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 260,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final evt = filtered[index];
                      final alreadyApplied = myApps.any((a) => a.eventId == evt.id && a.freelancerId == user.id);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.bgContainer, borderRadius: BorderRadius.circular(4)),
                              child: Text(evt.type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.mapPin, size: 12, color: AppColors.success),
                                const SizedBox(width: 3),
                                Text(
                                  evt.city,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(evt.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('${evt.date} • ${evt.venue}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            const SizedBox(height: 8),
                            Text(
                              evt.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMain),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurfaceSubtle,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Budget: ${CurrencyFormatter.format(evt.budget)}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, fontFamily: 'monospace', color: AppColors.primary),
                              ),
                              Text('Radius: ${evt.proximityKm} km', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.go('/freelancer/event/${evt.id}'),
                                child: const Text('View Details'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: alreadyApplied ? AppColors.bgContainer : AppColors.success,
                                  foregroundColor: alreadyApplied ? AppColors.textMuted : Colors.white,
                                ),
                                onPressed: alreadyApplied
                                    ? null
                                    : () async {
                                        try {
                                          final res = await ref.read(freelancerProvider.notifier).applyToEvent(
                                                evt.id,
                                                evt.name,
                                                user.id,
                                                user.primaryRole,
                                                user.expectedRate,
                                              );
                                          if (res && context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('✨ Applied to ${evt.name}!'),
                                                backgroundColor: AppColors.success,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Application error: $e'),
                                                backgroundColor: AppColors.danger,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (alreadyApplied) ...[
                                      const Icon(LucideIcons.check, size: 14),
                                      const SizedBox(width: 4),
                                      const Text('Applied'),
                                    ] else
                                      const Text('Apply Now →'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
