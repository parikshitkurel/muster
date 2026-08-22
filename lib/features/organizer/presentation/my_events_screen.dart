import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/event.dart';
import '../../../data/repositories/event_repository.dart';

class MyEventsScreen extends ConsumerStatefulWidget {
  const MyEventsScreen({super.key});

  @override
  ConsumerState<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends ConsumerState<MyEventsScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final eventState = ref.watch(eventsProvider);
    final events = eventState.events;
    final isMobile = ResponsiveLayout.isMobile(context);

    final filtered = events.where((e) {
      final matchesSearch = e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.venue.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_selectedFilter == 'Published') return e.status == EventStatus.published;
      if (_selectedFilter == 'Confirmed') return e.status == EventStatus.crewConfirmed;
      if (_selectedFilter == 'Draft') return e.status == EventStatus.draft;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — responsive
            if (isMobile) ...[
              Text(
                'My Events Roster',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage events, view applicants, and review AI crew allocations.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/organizer/create-event'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create New Event'),
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Events Roster',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Manage all created production events, view live applicants, and review AI crew allocations.',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/organizer/create-event'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create New Event'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // Search + Filter — responsive
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: const InputDecoration(
                              hintText: 'Search events...',
                              prefixIcon: Icon(Icons.search, size: 18),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: ['All', 'Published', 'Confirmed', 'Draft'].map((f) {
                              final isSel = _selectedFilter == f;
                              return ChoiceChip(
                                label: Text(f, style: const TextStyle(fontSize: 12)),
                                selected: isSel,
                                onSelected: (_) => setState(() => _selectedFilter = f),
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.bgSurfaceSubtle,
                              );
                            }).toList(),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (v) => setState(() => _searchQuery = v),
                              decoration: const InputDecoration(
                                hintText: 'Search events by name, venue, city...',
                                prefixIcon: Icon(Icons.search, size: 18),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Wrap(
                            spacing: 6,
                            children: ['All', 'Published', 'Confirmed', 'Draft'].map((f) {
                              final isSel = _selectedFilter == f;
                              return ChoiceChip(
                                label: Text(f, style: const TextStyle(fontSize: 12)),
                                selected: isSel,
                                onSelected: (_) => setState(() => _selectedFilter = f),
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.bgSurfaceSubtle,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Event cards — responsive
            filtered.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.search_off, size: 40, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text('No events found matching your filter.', style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final evt = filtered[index];
                      if (isMobile) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(evt.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text(
                                  '${evt.date} • ${evt.venue} • ${evt.city}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: evt.requirements
                                      .map((r) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.bgSurfaceSubtle,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: AppColors.border),
                                            ),
                                            child: Text('${r.role} (${r.quantity})', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  CurrencyFormatter.format(evt.budget),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, fontFamily: 'monospace', color: AppColors.primary),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => context.go('/organizer/applicants/${evt.id}'),
                                        child: Text('Applicants (${evt.applicantCount})', overflow: TextOverflow.ellipsis),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => context.go('/organizer/recommendation/${evt.id}'),
                                        child: const Text('AI Optimizer →', overflow: TextOverflow.ellipsis),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Desktop card
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(evt.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('${evt.date} • ${evt.venue} • ${evt.city}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: evt.requirements
                                          .map((r) => Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.bgSurfaceSubtle,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: AppColors.border),
                                                ),
                                                child: Text('${r.role} (${r.quantity})', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(CurrencyFormatter.format(evt.budget), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'monospace', color: AppColors.primary)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      OutlinedButton(
                                        onPressed: () => context.go('/organizer/applicants/${evt.id}'),
                                        child: Text('Applicants (${evt.applicantCount})'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () => context.go('/organizer/recommendation/${evt.id}'),
                                        child: const Text('AI Optimizer →'),
                                      ),
                                    ],
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
