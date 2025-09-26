import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buildbeacon/app/providers.dart';
import 'package:buildbeacon/data/models/build_models_simple.dart';
import 'package:buildbeacon/theme.dart';

class JobsFilterBar extends ConsumerStatefulWidget {
  const JobsFilterBar({super.key});

  @override
  ConsumerState<JobsFilterBar> createState() => _JobsFilterBarState();
}

class _JobsFilterBarState extends ConsumerState<JobsFilterBar> {
  BuildStatus? _selectedStatus;
  SourceType? _selectedSourceType;
  BuildType? _selectedBuildType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'Status',
              value: _selectedStatus?.name,
              onTap: () => _showStatusFilter(context),
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              label: 'Source',
              value: _selectedSourceType?.name,
              onTap: () => _showSourceTypeFilter(context),
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              label: 'Build Type',
              value: _selectedBuildType?.name.toUpperCase(),
              onTap: () => _showBuildTypeFilter(context),
            ),
            const SizedBox(width: 12),
            if (_hasActiveFilters())
              _buildClearButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    String? value,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: hasValue 
              ? LightModeColors.lightPrimary.withValues(alpha: 0.1)
              : LightModeColors.lightNeutral100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasValue
                ? LightModeColors.lightPrimary.withValues(alpha: 0.3)
                : LightModeColors.lightNeutral200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasValue ? '$label: $value' : label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: hasValue 
                    ? LightModeColors.lightPrimary
                    : LightModeColors.lightNeutral600,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: hasValue 
                  ? LightModeColors.lightPrimary
                  : LightModeColors.lightNeutral400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return InkWell(
      onTap: _clearFilters,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.clear,
              size: 16,
              color: LightModeColors.lightNeutral500,
            ),
            const SizedBox(width: 4),
            Text(
              'Clear',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: LightModeColors.lightNeutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusFilter(BuildContext context) {
    showModalBottomSheet<BuildStatus>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterBottomSheet<BuildStatus>(
        title: 'Filter by Status',
        options: BuildStatus.values,
        selectedValue: _selectedStatus,
        getLabel: (status) => _getStatusLabel(status),
        onSelected: (status) {
          setState(() => _selectedStatus = status);
          // Simplified: refresh jobs list (no server-side filters wired yet)
          ref.refresh(jobsListProvider);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSourceTypeFilter(BuildContext context) {
    showModalBottomSheet<SourceType>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterBottomSheet<SourceType>(
        title: 'Filter by Source',
        options: SourceType.values,
        selectedValue: _selectedSourceType,
        getLabel: (source) => _getSourceLabel(source),
        onSelected: (source) {
          setState(() => _selectedSourceType = source);
          // Simplified: refresh jobs list (no server-side filters wired yet)
          ref.refresh(jobsListProvider);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showBuildTypeFilter(BuildContext context) {
    showModalBottomSheet<BuildType>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterBottomSheet<BuildType>(
        title: 'Filter by Build Type',
        options: BuildType.values,
        selectedValue: _selectedBuildType,
        getLabel: (type) => type.name.toUpperCase(),
        onSelected: (type) {
          setState(() => _selectedBuildType = type);
          // Simplified: refresh jobs list (no server-side filters wired yet)
          ref.refresh(jobsListProvider);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedSourceType = null;
      _selectedBuildType = null;
    });
    // Simplified: just refresh the jobs list
    ref.refresh(jobsListProvider);
  }

  bool _hasActiveFilters() {
    return _selectedStatus != null || 
           _selectedSourceType != null || 
           _selectedBuildType != null;
  }

  String _getStatusLabel(BuildStatus status) {
    switch (status) {
      case BuildStatus.created:
        return 'Created';
      case BuildStatus.queued:
        return 'Queued';
      case BuildStatus.downloadingSource:
        return 'Downloading source';
      case BuildStatus.preSteps:
        return 'Pre-steps';
      case BuildStatus.building:
        return 'Building';
      case BuildStatus.postSteps:
        return 'Post-steps';
      case BuildStatus.packaging:
        return 'Packaging';
      case BuildStatus.success:
        return 'Success';
      case BuildStatus.failed:
        return 'Failed';
      case BuildStatus.canceled:
        return 'Canceled';
    }
  }

  String _getSourceLabel(SourceType source) {
    switch (source) {
      case SourceType.uploadZip:
        return 'Upload ZIP';
      case SourceType.flutterFlow:
        return 'FlutterFlow';
      case SourceType.gitRepo:
        return 'Git Repository';
    }
  }
}

class _FilterBottomSheet<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final T? selectedValue;
  final String Function(T) getLabel;
  final void Function(T) onSelected;

  const _FilterBottomSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.getLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 16),
          ...options.map((option) => ListTile(
            title: Text(getLabel(option)),
            trailing: selectedValue == option
                ? Icon(
                    Icons.check,
                    color: LightModeColors.lightPrimary,
                  )
                : null,
            onTap: () => onSelected(option),
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}