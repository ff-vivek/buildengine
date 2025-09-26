import 'package:flutter/material.dart';
import 'package:buildbeacon/theme.dart';
import 'package:buildbeacon/utils/validators.dart';

class BuildStepsConfigStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final List<String> preSteps;
  final List<String> postSteps;
  final ValueChanged<List<String>> onPreStepsChanged;
  final ValueChanged<List<String>> onPostStepsChanged;

  const BuildStepsConfigStep({
    super.key,
    required this.formKey,
    required this.preSteps,
    required this.postSteps,
    required this.onPreStepsChanged,
    required this.onPostStepsChanged,
  });

  @override
  State<BuildStepsConfigStep> createState() => _BuildStepsConfigStepState();
}

class _BuildStepsConfigStepState extends State<BuildStepsConfigStep> {
  late List<String> _preSteps;
  late List<String> _postSteps;
  final List<TextEditingController> _preStepControllers = [];
  final List<TextEditingController> _postStepControllers = [];

  @override
  void initState() {
    super.initState();
    _preSteps = List.from(widget.preSteps);
    _postSteps = List.from(widget.postSteps);
    _initializeControllers();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _initializeControllers() {
    _disposeControllers();
    
    _preStepControllers.clear();
    for (int i = 0; i < _preSteps.length; i++) {
      _preStepControllers.add(TextEditingController(text: _preSteps[i]));
    }
    
    _postStepControllers.clear();
    for (int i = 0; i < _postSteps.length; i++) {
      _postStepControllers.add(TextEditingController(text: _postSteps[i]));
    }
  }

  void _disposeControllers() {
    for (final controller in _preStepControllers) {
      controller.dispose();
    }
    for (final controller in _postStepControllers) {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildPreStepsSection(context),
            const SizedBox(height: 32),
            _buildPostStepsSection(context),
            const SizedBox(height: 32),
            _buildCommandExamples(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Build Steps',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure custom commands to run before and after the build.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: LightModeColors.lightNeutral600,
          ),
        ),
      ],
    );
  }

  Widget _buildPreStepsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pre-Build Steps',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Commands to run before building (e.g., flutter pub get)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: LightModeColors.lightNeutral600,
          ),
        ),
        const SizedBox(height: 16),
        ..._buildStepsList(_preSteps, _preStepControllers, true),
        const SizedBox(height: 12),
        _buildAddStepButton(true),
      ],
    );
  }

  Widget _buildPostStepsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Post-Build Steps',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Commands to run after successful build (e.g., dart run tool/post_build.dart)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: LightModeColors.lightNeutral600,
          ),
        ),
        const SizedBox(height: 16),
        ..._buildStepsList(_postSteps, _postStepControllers, false),
        const SizedBox(height: 12),
        _buildAddStepButton(false),
      ],
    );
  }

  List<Widget> _buildStepsList(
    List<String> steps,
    List<TextEditingController> controllers,
    bool isPreSteps,
  ) {
    if (steps.isEmpty) {
      return [_buildEmptyStepsMessage()];
    }

    return steps.asMap().entries.map((entry) {
      final index = entry.key;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildStepField(index, controllers[index], isPreSteps),
      );
    }).toList();
  }

  Widget _buildStepField(int index, TextEditingController controller, bool isPreSteps) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 48,
          decoration: BoxDecoration(
            color: LightModeColors.lightNeutral100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: LightModeColors.lightNeutral600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Command',
              hintText: 'flutter pub get',
              prefixIcon: const Icon(Icons.terminal),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return null; // Optional
              return Validators.validateCommand(value);
            },
            onChanged: (value) => _updateStep(index, value, isPreSteps),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () => _removeStep(index, isPreSteps),
          icon: Icon(
            Icons.delete_outline,
            color: LightModeColors.lightError,
          ),
          tooltip: 'Remove step',
        ),
      ],
    );
  }

  Widget _buildEmptyStepsMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LightModeColors.lightNeutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LightModeColors.lightNeutral200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: LightModeColors.lightNeutral400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No steps configured. Click "Add Step" to add custom commands.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: LightModeColors.lightNeutral600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddStepButton(bool isPreSteps) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _addStep(isPreSteps),
        icon: const Icon(Icons.add),
        label: const Text('Add Step'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCommandExamples(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LightModeColors.lightNeutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LightModeColors.lightNeutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: LightModeColors.lightPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Command Examples',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: LightModeColors.lightPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCommandExample('Pre-Build Steps:', [
            'flutter clean',
            'flutter pub get',
            'dart run build_runner build',
            'flutter packages get',
          ]),
          const SizedBox(height: 16),
          _buildCommandExample('Post-Build Steps:', [
            'dart run tool/post_build.dart',
            'flutter test',
            'dart format --output=none --set-exit-if-changed .',
          ]),
          const SizedBox(height: 16),
          _buildSecurityNote(context),
        ],
      ),
    );
  }

  Widget _buildCommandExample(String title, List<String> commands) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...commands.map((cmd) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(right: 8, top: 6),
                decoration: BoxDecoration(
                  color: LightModeColors.lightNeutral400,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  cmd,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: LightModeColors.lightNeutral700,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildSecurityNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: Colors.orange[700],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Security: Only "flutter" and "dart" commands are allowed. Special characters and shell operators are blocked.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.orange[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addStep(bool isPreSteps) {
    setState(() {
      if (isPreSteps) {
        _preSteps.add('');
        _preStepControllers.add(TextEditingController());
      } else {
        _postSteps.add('');
        _postStepControllers.add(TextEditingController());
      }
    });
    _notifyChanges();
  }

  void _removeStep(int index, bool isPreSteps) {
    setState(() {
      if (isPreSteps) {
        _preSteps.removeAt(index);
        _preStepControllers[index].dispose();
        _preStepControllers.removeAt(index);
      } else {
        _postSteps.removeAt(index);
        _postStepControllers[index].dispose();
        _postStepControllers.removeAt(index);
      }
    });
    _notifyChanges();
  }

  void _updateStep(int index, String value, bool isPreSteps) {
    if (isPreSteps) {
      _preSteps[index] = value;
    } else {
      _postSteps[index] = value;
    }
    _notifyChanges();
  }

  void _notifyChanges() {
    // Filter out empty steps
    final filteredPreSteps = _preSteps.where((step) => step.trim().isNotEmpty).toList();
    final filteredPostSteps = _postSteps.where((step) => step.trim().isNotEmpty).toList();
    
    widget.onPreStepsChanged(filteredPreSteps);
    widget.onPostStepsChanged(filteredPostSteps);
  }
}