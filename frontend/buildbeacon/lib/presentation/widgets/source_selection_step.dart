// Removed dart:io in favor of file_picker PlatformFile
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:buildbeacon/data/models/build_models_simple.dart';
import 'package:buildbeacon/theme.dart';
import 'package:buildbeacon/utils/constants.dart';
import 'package:buildbeacon/utils/validators.dart';

class SourceSelectionStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final SourceType selectedSourceType;
  final PlatformFile? selectedFile;
  final String uploadProgress; // human-readable status like "Uploading: 42%" or "Upload complete"
  final double uploadProgressValue; // 0.0 - 1.0
  final bool isUploading;
  final String ffUrl;
  final String ffToken;
  // Parsed/structured FF fields
  final String ffProjectId;
  final String ffEndpoint;
  final String ffEnvironment;
  final bool ffIncludeAssets;
  // Git
  final String gitUrl;
  final String branch;
  final ValueChanged<SourceType> onSourceTypeChanged;
  final ValueChanged<PlatformFile?> onFileSelected;
  final ValueChanged<String> onFFUrlChanged;
  final ValueChanged<String> onFFTokenChanged;
  final ValueChanged<String> onFFProjectIdChanged;
  final ValueChanged<String> onFFEndpointChanged;
  final ValueChanged<String> onFFEnvironmentChanged;
  final ValueChanged<bool> onFFIncludeAssetsChanged;
  final ValueChanged<String> onGitUrlChanged;
  final ValueChanged<String> onBranchChanged;

  const SourceSelectionStep({
    super.key,
    required this.formKey,
    required this.selectedSourceType,
    required this.selectedFile,
    required this.uploadProgress,
    this.uploadProgressValue = 0,
    this.isUploading = false,
    required this.ffUrl,
    required this.ffToken,
    required this.ffProjectId,
    required this.ffEndpoint,
    required this.ffEnvironment,
    required this.ffIncludeAssets,
    required this.gitUrl,
    required this.branch,
    required this.onSourceTypeChanged,
    required this.onFileSelected,
    required this.onFFUrlChanged,
    required this.onFFTokenChanged,
    required this.onFFProjectIdChanged,
    required this.onFFEndpointChanged,
    required this.onFFEnvironmentChanged,
    required this.onFFIncludeAssetsChanged,
    required this.onGitUrlChanged,
    required this.onBranchChanged,
  });

  @override
  State<SourceSelectionStep> createState() => _SourceSelectionStepState();
}

class _SourceSelectionStepState extends State<SourceSelectionStep>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers to support programmatic updates (parsing CLI input)
  late final TextEditingController _ffCommandController;
  late final TextEditingController _ffUrlController;
  late final TextEditingController _ffTokenController;
  late final TextEditingController _branchController;

  // Extra parsed fields (UI only for visibility/confirmation)
  late final TextEditingController _ffProjectIdController;
  late final TextEditingController _ffEndpointController;
  late final TextEditingController _ffEnvironmentController;
  bool _ffIncludeAssets = false;

  String _maskToken(String token) {
    if (token.isEmpty) return '';
    if (token.length <= 8) return '*' * token.length;
    final start = token.substring(0, 4);
    final end = token.substring(token.length - 4);
    return '$start***$end';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AppConstants.enableGitRepoSource ? 3 : 2,
      vsync: this,
      initialIndex: _getTabIndex(widget.selectedSourceType),
    );
    _tabController.addListener(_onTabChanged);

    // Init controllers
    _ffCommandController = TextEditingController();
    _ffUrlController = TextEditingController(text: widget.ffUrl);
    _ffTokenController = TextEditingController(text: widget.ffToken);
    _branchController = TextEditingController(text: widget.branch);
    _ffProjectIdController = TextEditingController(text: widget.ffProjectId);
    _ffEndpointController = TextEditingController(text: widget.ffEndpoint);
    _ffEnvironmentController = TextEditingController(text: widget.ffEnvironment);
    _ffIncludeAssets = widget.ffIncludeAssets;

    // Forward changes upstream + logs
    _ffUrlController.addListener(() {
      final url = _ffUrlController.text;
      // ignore: avoid_print
      print('[FF] URL changed -> $url');
      widget.onFFUrlChanged(url);
    });
    _ffTokenController.addListener(() {
      final token = _ffTokenController.text;
      // ignore: avoid_print
      print('[FF] Token changed -> ${_maskToken(token)}');
      widget.onFFTokenChanged(token);
    });
    _ffProjectIdController.addListener(() {
      final v = _ffProjectIdController.text;
      // ignore: avoid_print
      print('[FF] ProjectId changed -> $v');
      widget.onFFProjectIdChanged(v);
    });
    _ffEndpointController.addListener(() {
      final v = _ffEndpointController.text;
      // ignore: avoid_print
      print('[FF] Endpoint changed -> $v');
      widget.onFFEndpointChanged(v);
    });
    _ffEnvironmentController.addListener(() {
      final v = _ffEnvironmentController.text;
      // ignore: avoid_print
      print('[FF] Environment changed -> $v');
      widget.onFFEnvironmentChanged(v);
    });
    _branchController.addListener(() {
      final branch = _branchController.text;
      // ignore: avoid_print
      print('[FF] Branch changed -> $branch');
      widget.onBranchChanged(branch);
    });
  }

  @override
  void didUpdateWidget(covariant SourceSelectionStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ffUrl != widget.ffUrl && _ffUrlController.text != widget.ffUrl) {
      _ffUrlController.text = widget.ffUrl;
    }
    if (oldWidget.ffToken != widget.ffToken && _ffTokenController.text != widget.ffToken) {
      _ffTokenController.text = widget.ffToken;
    }
    if (oldWidget.ffProjectId != widget.ffProjectId && _ffProjectIdController.text != widget.ffProjectId) {
      _ffProjectIdController.text = widget.ffProjectId;
    }
    if (oldWidget.ffEndpoint != widget.ffEndpoint && _ffEndpointController.text != widget.ffEndpoint) {
      _ffEndpointController.text = widget.ffEndpoint;
    }
    if (oldWidget.ffEnvironment != widget.ffEnvironment && _ffEnvironmentController.text != widget.ffEnvironment) {
      _ffEnvironmentController.text = widget.ffEnvironment;
    }
    if (oldWidget.ffIncludeAssets != widget.ffIncludeAssets && _ffIncludeAssets != widget.ffIncludeAssets) {
      _ffIncludeAssets = widget.ffIncludeAssets;
    }
    if (oldWidget.branch != widget.branch && _branchController.text != widget.branch) {
      _branchController.text = widget.branch;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ffCommandController.dispose();
    _ffUrlController.dispose();
    _ffTokenController.dispose();
    _branchController.dispose();
    _ffProjectIdController.dispose();
    _ffEndpointController.dispose();
    _ffEnvironmentController.dispose();
    super.dispose();
  }

  int _getTabIndex(SourceType type) {
    switch (type) {
      case SourceType.uploadZip:
        return 0;
      case SourceType.flutterFlow:
        return 1;
      case SourceType.gitRepo:
        return AppConstants.enableGitRepoSource ? 2 : 0;
    }
  }

  void _onTabChanged() {
    final sourceTypes = [
      SourceType.uploadZip,
      SourceType.flutterFlow,
      if (AppConstants.enableGitRepoSource) SourceType.gitRepo,
    ];

    if (_tabController.index < sourceTypes.length) {
      widget.onSourceTypeChanged(sourceTypes[_tabController.index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          _buildHeader(context),
          _buildTabBar(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUploadTab(),
                _buildFlutterFlowTab(),
                if (AppConstants.enableGitRepoSource) _buildGitTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Source',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select how you want to provide your Flutter project.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LightModeColors.lightNeutral600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: LightModeColors.lightNeutral100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: LightModeColors.lightPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: LightModeColors.lightNeutral600,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        tabs: [
          const Padding(padding: EdgeInsets.all(16.0), child: Tab(text: 'Upload ZIP')),
          const Tab(text: 'FlutterFlow'),
          if (AppConstants.enableGitRepoSource) const Tab(text: 'Git Repo'),
        ],
      ),
    );
  }

  Widget _buildUploadTab() {
    final hasSelection = widget.selectedFile != null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Upload Project ZIP'),
          const SizedBox(height: 16),
          _buildUploadArea(),
          if (hasSelection) ...[
            const SizedBox(height: 16),
            _buildFileInfoCard(
              name: widget.selectedFile!.name,
              size: widget.selectedFile!.size,
              onClear: () {
                if (!widget.isUploading) {
                  widget.onFileSelected(null);
                }
              },
            ),
          ],
          if (hasSelection && (widget.isUploading || widget.uploadProgress.isNotEmpty)) ...[
            const SizedBox(height: 16),
            _buildProgressStatus(),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildUploadArea() {
    final isDisabled = widget.isUploading;
    return GestureDetector(
      onTap: isDisabled ? null : _selectFile,
      child: Opacity(
        opacity: isDisabled ? 0.7 : 1,
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(
              color: LightModeColors.lightNeutral300,
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
            color: LightModeColors.lightNeutral50,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 48,
                color: LightModeColors.lightNeutral400,
              ),
              const SizedBox(height: 16),
              Text(
                isDisabled ? 'Uploading in progress...' : 'Tap to select ZIP file',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: LightModeColors.lightNeutral600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Max file size: ${Validators.formatFileSize(AppConstants.maxFileSize)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: LightModeColors.lightNeutral500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileInfoCard({required String name, required int size, required VoidCallback onClear}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LightModeColors.lightPrimaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_zip,
            color: LightModeColors.lightPrimary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  Validators.formatFileSize(size),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LightModeColors.lightNeutral600,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClear,
            color: LightModeColors.lightNeutral500,
          ),
        ],
      ),
    );
  }

  Widget _buildBranchField() {
    return TextFormField(
      controller: _branchController,
      decoration: const InputDecoration(
        labelText: 'Branch',
        hintText: 'main',
        prefixIcon: Icon(Icons.account_tree_outlined),
      ),
      validator: Validators.validateBranch,
      onChanged: widget.onBranchChanged,
    );
  }

  Widget _buildFlutterFlowTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('FlutterFlow Project'),
            const SizedBox(height: 16),

            // Paste command field with parse action
            TextFormField(
              controller: _ffCommandController,
              decoration: InputDecoration(
                labelText: 'Paste FlutterFlow command',
                hintText: 'flutterflow export-code --project ... --endpoint ... --token ...',
                prefixIcon: const Icon(Icons.terminal),
                suffixIcon: IconButton(
                  tooltip: 'Parse and fill',
                  icon: const Icon(Icons.playlist_add_check),
                  onPressed: _handleParseCommand,
                ),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _ffUrlController,
              decoration: const InputDecoration(
                labelText: 'Project URL',
                hintText: 'https://app.flutterflow.io/project/...',
                prefixIcon: Icon(Icons.link),
              ),
              validator: Validators.validateFlutterFlowUrl,
              onChanged: widget.onFFUrlChanged,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ffTokenController,
              decoration: const InputDecoration(
                labelText: 'Access Token',
                hintText: 'Your FlutterFlow access token',
                prefixIcon: Icon(Icons.key),
              ),
              obscureText: true,
              validator: Validators.validateToken,
              onChanged: widget.onFFTokenChanged,
            ),
            const SizedBox(height: 16),
            _buildBranchField(),

            const SizedBox(height: 24),
            _buildSectionTitle('Parsed Details'),
            const SizedBox(height: 8),
            _buildWarningCard(
              'We parsed these fields from your command. You can edit them as needed. Only URL and token are required to continue.',
            ),
            const SizedBox(height: 16),

            // Extra informational fields (optional)
            TextFormField(
              controller: _ffProjectIdController,
              decoration: const InputDecoration(
                labelText: 'Project ID',
                hintText: 'e.g., error-prone-app-hcoay3',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ffEndpointController,
              decoration: const InputDecoration(
                labelText: 'API Endpoint',
                hintText: 'https://api.flutterflow.io/v2',
                prefixIcon: Icon(Icons.cloud_outlined),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return null; // optional
                return Validators.validateUrl(v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ffEnvironmentController,
              decoration: const InputDecoration(
                labelText: 'Project Environment',
                hintText: 'Production',
                prefixIcon: Icon(Icons.settings_suggest_outlined),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Include Assets'),
              value: _ffIncludeAssets,
              onChanged: (val) {
                setState(() => _ffIncludeAssets = val);
                // ignore: avoid_print
                print('[FF] IncludeAssets changed -> $val');
                widget.onFFIncludeAssetsChanged(val);
              },
              secondary: const Icon(Icons.inventory_2_outlined),
            ),

            const SizedBox(height: 16),
            _buildWarningCard(
              'Your access token will be used only for this build and won\'t be stored permanently.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGitTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Git Repository'),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: widget.gitUrl,
            decoration: const InputDecoration(
              labelText: 'Git URL',
              hintText: 'https://github.com/user/repo.git',
              prefixIcon: Icon(Icons.account_tree),
            ),
            validator: Validators.validateGitUrl,
            onChanged: widget.onGitUrlChanged,
          ),
          const SizedBox(height: 16),
          _buildBranchField(),
          const SizedBox(height: 16),
          _buildWarningCard(
            'Public repositories only. Private repos require authentication setup.',
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LightModeColors.lightNeutral100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LightModeColors.lightNeutral200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: LightModeColors.lightNeutral500,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LightModeColors.lightNeutral600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStatus() {
    final complete = widget.uploadProgressValue >= 1.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: complete
            ? LightModeColors.lightTertiary.withValues(alpha: 0.1)
            : LightModeColors.lightPrimaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                complete ? Icons.check_circle : Icons.cloud_upload,
                color: complete ? LightModeColors.lightTertiary : LightModeColors.lightPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.uploadProgress.isEmpty
                      ? (complete ? 'Upload complete (100%)' : 'Uploading...')
                      : widget.uploadProgress,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: complete ? LightModeColors.lightTertiary : LightModeColors.lightPrimary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: widget.isUploading ? widget.uploadProgressValue : (complete ? 1.0 : null),
              minHeight: 8,
              backgroundColor: Colors.white,
              color: complete ? LightModeColors.lightTertiary : LightModeColors.lightPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      allowMultiple: false,
      withData: true, // ensure bytes are available on all platforms
    );

    if (result != null && result.files.isNotEmpty) {
      final platformFile = result.files.single;
      final name = platformFile.name;
      final data = platformFile.bytes; // should be non-null due to withData: true

      // Debug prints
      // ignore: avoid_print
      print('selectedFile Name: $name');
      // ignore: avoid_print
      print('selectedFile Size: ${platformFile.size}');
      // ignore: avoid_print
      print('selectedFile HasBytes: ${data != null}');

      // Basic validation using name/bytes
      String? error;

      // Extension check
      final extension = name.toLowerCase().split('.').last;
      if (!AppConstants.allowedFileExtensions.contains('.$extension')) {
        error = AppConstants.invalidFileType;
      }

      // Size check
      if (error == null) {
        final size = platformFile.size;
        if (size <= 0) {
          error = AppConstants.invalidFileType;
        } else if (size > AppConstants.maxFileSize) {
          error = AppConstants.fileTooLarge;
        }
      }

      // Deep validation: ZIP magic header (PK..)
      if (error == null) {
        try {
          final header = (data != null && data.length >= 4)
              ? data.sublist(0, 4)
              : <int>[];

          final isZipMagic = header.length >= 4 &&
              header[0] == 0x50 && // 'P'
              header[1] == 0x4B && // 'K'
              (
                // local file header       PK\x03\x04
                (header[2] == 0x03 && header[3] == 0x04) ||
                // empty archive           PK\x05\x06
                (header[2] == 0x05 && header[3] == 0x06) ||
                // spanned/split archive   PK\x07\x08
                (header[2] == 0x07 && header[3] == 0x08)
              );

          if (!isZipMagic) {
            error = AppConstants.invalidFileType; // Reuse existing message
          }
        } catch (_) {
          // If we can't read the file header, treat as invalid
          error = AppConstants.invalidFileType;
        }
      }

      if (!mounted) return;

      if (error == null) {
        widget.onFileSelected(platformFile);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected: $name (${Validators.formatFileSize(platformFile.size)})'),
            backgroundColor: LightModeColors.lightTertiary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: LightModeColors.lightError,
          ),
        );
      }
    }
  }

  void _handleParseCommand() {
    String input = _ffCommandController.text.trim();
    // ignore: avoid_print
    print('[FF Parse] Raw command: ' + input);
    if (input.isEmpty) {
      _showSnack('Please paste the FlutterFlow command first.', isError: true);
      return;
    }

    // Normalize unicode dashes to ASCII hyphen
    input = input
        .replaceAll('\u2013', '-') // en dash
        .replaceAll('\u2014', '-') // em dash
        .replaceAll('\u2212', '-') // minus sign
        .replaceAll('\u2012', '-') // figure dash
        .replaceAll('\u2010', '-'); // hyphen

    // Basic sanity check (non-blocking)
    if (!input.contains('flutterflow') || !input.contains('export-code')) {
      _showSnack('This doesn\'t look like a FlutterFlow export-code command.', isError: true);
      // Continue to attempt parsing anyway
    }

    // Tokenize while respecting quotes and equals syntax
    final tokenRegex = RegExp("(\"([^\\\"]*)\"|'([^']*)'|\\S+)");
    final matches = tokenRegex.allMatches(input).toList();
    final tokens = <String>[];
    for (final m in matches) {
      final whole = m.group(0) ?? '';
      final dq = m.group(2);
      final sq = m.group(3);
      final token = dq ?? sq ?? whole;
      tokens.add(token);
    }

    // ignore: avoid_print
    print('[FF Parse] Tokens: ' + tokens.join(' | '));

    String? projectId;
    String? endpoint;
    String? environment;
    bool includeAssets = false;
    String? token;

    String? _stripQuotes(String? v) {
      if (v == null) return null;
      var s = v.trim();
      if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith('\'') && s.endsWith('\''))) {
        s = s.substring(1, s.length - 1);
      }
      return s;
    }

    String? _valueAfterFlag(int i) {
      // Return value if the next token exists and is not another flag
      if (i + 1 < tokens.length) {
        final next = tokens[i + 1];
        if (!next.startsWith('--')) {
          return _stripQuotes(next);
        }
      }
      return null;
    }

    for (int i = 0; i < tokens.length; i++) {
      var t = tokens[i];
      if (!t.startsWith('--')) continue;

      // Support --flag=value
      if (t.contains('=')) {
        final idx = t.indexOf('=');
        final name = t.substring(2, idx).toLowerCase();
        final value = _stripQuotes(t.substring(idx + 1));
        switch (name) {
          case 'project':
            projectId = value;
            break;
          case 'endpoint':
            endpoint = value;
            break;
          case 'project-environment':
            environment = value;
            break;
          case 'token':
            token = value;
            break;
          case 'include-assets':
            includeAssets = true; // presence is enough
            break;
        }
        continue;
      }

      final flag = t.substring(2).toLowerCase();
      switch (flag) {
        case 'project':
          projectId = _valueAfterFlag(i);
          break;
        case 'endpoint':
          endpoint = _valueAfterFlag(i);
          break;
        case 'project-environment':
          environment = _valueAfterFlag(i);
          break;
        case 'token':
          token = _valueAfterFlag(i);
          break;
        case 'include-assets':
          includeAssets = true;
          break;
      }
    }

    // ignore: avoid_print
    print('[FF Parse] projectId=' + (projectId ?? 'null') + ', endpoint=' + (endpoint ?? 'null') + ', env=' + (environment ?? 'null') + ', includeAssets=' + includeAssets.toString() + ', token=' + _maskToken(token ?? ''));

    setState(() {
      if (projectId != null && projectId!.isNotEmpty) {
        _ffProjectIdController.text = projectId!;
        final url = 'https://app.flutterflow.io/project/$projectId';
        _ffUrlController.text = url;
      }
      if (endpoint != null && endpoint!.isNotEmpty) {
        _ffEndpointController.text = endpoint!;
      }
      if (environment != null && environment!.isNotEmpty) {
        _ffEnvironmentController.text = environment!;
      }
      _ffIncludeAssets = includeAssets;
      if (token != null && token!.isNotEmpty) {
        _ffTokenController.text = token!;
      }
    });

    // Explicitly propagate to parent as well
    if (projectId != null && projectId!.isNotEmpty) {
      final url = 'https://app.flutterflow.io/project/$projectId';
      // ignore: avoid_print
      print('[FF Parse] Propagating URL to parent: ' + url);
      widget.onFFUrlChanged(url);
      widget.onFFProjectIdChanged(projectId!);
    }
    if (endpoint != null && endpoint!.isNotEmpty) {
      // ignore: avoid_print
      print('[FF Parse] Propagating endpoint to parent: ' + endpoint!);
      widget.onFFEndpointChanged(endpoint!);
    }
    if (environment != null && environment!.isNotEmpty) {
      // ignore: avoid_print
      print('[FF Parse] Propagating environment to parent: ' + environment!);
      widget.onFFEnvironmentChanged(environment!);
    }
    // includeAssets presence
    widget.onFFIncludeAssetsChanged(includeAssets);
    if (token != null && token!.isNotEmpty) {
      // ignore: avoid_print
      print('[FF Parse] Propagating token to parent: ' + _maskToken(token!));
      widget.onFFTokenChanged(token!);
    }

    _showSnack('Parsed and filled fields from the command.');
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? LightModeColors.lightError : LightModeColors.lightTertiary,
      ),
    );
  }
}
