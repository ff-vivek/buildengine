import 'package:file_picker/file_picker.dart';
// removed dart:typed_data; using PlatformFile
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buildbeacon/app/providers.dart';
import 'package:buildbeacon/data/models/build_models_simple.dart';
import 'package:buildbeacon/app/router.dart';
import 'package:buildbeacon/presentation/widgets/step_indicator.dart';
import 'package:buildbeacon/presentation/widgets/source_selection_step.dart';
import 'package:buildbeacon/presentation/widgets/build_config_step.dart';
import 'package:buildbeacon/presentation/widgets/build_steps_config_step.dart';
import 'package:buildbeacon/presentation/widgets/review_step.dart';
import 'package:buildbeacon/theme.dart';
import 'package:buildbeacon/utils/constants.dart';
import 'package:buildbeacon/utils/validators.dart';

class NewBuildScreen extends ConsumerStatefulWidget {
  const NewBuildScreen({super.key});

  @override
  ConsumerState<NewBuildScreen> createState() => _NewBuildScreenState();
}

class _NewBuildScreenState extends ConsumerState<NewBuildScreen> {
  final PageController _pageController = PageController();
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  int _currentStep = 0;
  bool _isCreating = false;

  // Step 1: Source
  SourceType _selectedSourceType = SourceType.uploadZip;
  PlatformFile? _selectedFile;
  String _uploadProgress = '';
  double _uploadProgressValue = 0.0;
  bool _isUploading = false;
  String? _uploadId; // store upload id once complete
  String _ffUrl = '';
  String _ffToken = '';
  String _ffProjectId = '';
  String _ffEndpoint = '';
  String _ffEnvironment = '';
  bool _ffIncludeAssets = false;
  String _gitUrl = '';
  String _branch = AppConstants.defaultBranch;

  // Step 2: Build Config
  String _flutterVersion = AppConstants.defaultFlutterVersion;
  BuildType _buildType = BuildType.release;
  String _targetFile = AppConstants.defaultTargetFile;
  List<BuildPlatform> _platforms = const [BuildPlatform.web];

  // Step 3: Pre/Post Steps
  final List<String> _preSteps = [];
  final List<String> _postSteps = [];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Build'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: const Text('Back'),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSourceStep(),
                _buildConfigStep(),
                _buildStepsConfigStep(),
                _buildReviewStep(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: StepIndicator(
        currentStep: _currentStep,
        totalSteps: 4,
        stepTitles: const [
          'Source',
          'Config',
          'Steps',
          'Review',
        ],
      ),
    );
  }

  Widget _buildSourceStep() {
    return SourceSelectionStep(
      formKey: _formKeys[0],
      selectedSourceType: _selectedSourceType,
      selectedFile: _selectedFile,
      uploadProgress: _uploadProgress,
      uploadProgressValue: _uploadProgressValue,
      isUploading: _isUploading,
      ffUrl: _ffUrl,
      ffToken: _ffToken,
      ffProjectId: _ffProjectId,
      ffEndpoint: _ffEndpoint,
      ffEnvironment: _ffEnvironment,
      ffIncludeAssets: _ffIncludeAssets,
      gitUrl: _gitUrl,
      branch: _branch,
      onSourceTypeChanged: (type) => setState(() {
        _selectedSourceType = type;
        // Reset upload state when switching source type
        if (type != SourceType.uploadZip) {
          _selectedFile = null;
          _uploadProgress = '';
          _uploadProgressValue = 0.0;
          _isUploading = false;
          _uploadId = null;
        }
      }),
      onFileSelected: (file) {
        setState(() {
          _selectedFile = file;
          _uploadProgress = '';
          _uploadProgressValue = 0.0;
          _uploadId = null;
        });
        if (file != null) {
          _beginUpload();
        } else {
          setState(() {
            _isUploading = false;
          });
        }
      },
      onFFUrlChanged: (url) => setState(() => _ffUrl = url),
      onFFTokenChanged: (token) => setState(() => _ffToken = token),
      onFFProjectIdChanged: (v) => setState(() => _ffProjectId = v),
      onFFEndpointChanged: (v) => setState(() => _ffEndpoint = v),
      onFFEnvironmentChanged: (v) => setState(() => _ffEnvironment = v),
      onFFIncludeAssetsChanged: (v) => setState(() => _ffIncludeAssets = v),
      onGitUrlChanged: (url) => setState(() => _gitUrl = url),
      onBranchChanged: (branch) => setState(() => _branch = branch),
    );
  }

  Widget _buildConfigStep() {
    return BuildConfigStep(
      formKey: _formKeys[1],
      flutterVersion: _flutterVersion,
      buildType: _buildType,
      targetFile: _targetFile,
      platforms: _platforms,
      onFlutterVersionChanged: (version) => setState(() => _flutterVersion = version),
      onBuildTypeChanged: (type) => setState(() => _buildType = type),
      onTargetFileChanged: (file) => setState(() => _targetFile = file),
      onPlatformsChanged: (list) => setState(() => _platforms = list),
    );
  }

  Widget _buildStepsConfigStep() {
    return BuildStepsConfigStep(
      formKey: _formKeys[2],
      preSteps: _preSteps,
      postSteps: _postSteps,
      onPreStepsChanged: (steps) => setState(() {
        _preSteps.clear();
        _preSteps.addAll(steps);
      }),
      onPostStepsChanged: (steps) => setState(() {
        _postSteps.clear();
        _postSteps.addAll(steps);
      }),
    );
  }

  Widget _buildReviewStep() {
    return ReviewStep(
      sourceType: _selectedSourceType,
      selectedFile: _selectedFile,
      ffUrl: _ffUrl,
      gitUrl: _gitUrl,
      branch: _branch,
      flutterVersion: _flutterVersion,
      buildType: _buildType,
      targetFile: _targetFile,
      preSteps: _preSteps,
      postSteps: _postSteps,
      platforms: _platforms,
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep < 3) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _canProceed() ? _nextStep : null,
                child: Text(_currentStep == 2 ? 'Review' : 'Continue'),
              ),
            ),
          ] else ...[
            Expanded(
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createBuild,
                child: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Build'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _validateSourceStep();
      case 1:
        return _validateConfigStep();
      case 2:
        return true; // Steps are optional
      case 3:
        return !_isCreating;
      default:
        return false;
    }
  }

  bool _validateSourceStep() {
    switch (_selectedSourceType) {
      case SourceType.uploadZip:
        // Require successful upload before continuing
        final fileOk = _selectedFile != null && Validators.validateFile(_selectedFile) == null;
        final uploaded = _uploadId != null && _uploadProgressValue >= 1.0;
        return fileOk && uploaded && !_isUploading;
      case SourceType.flutterFlow:
        return _ffUrl.isNotEmpty && _ffToken.isNotEmpty &&
               Validators.validateFlutterFlowUrl(_ffUrl) == null &&
               Validators.validateToken(_ffToken) == null;
      case SourceType.gitRepo:
        return _gitUrl.isNotEmpty && Validators.validateGitUrl(_gitUrl) == null;
    }
  }

  bool _validateConfigStep() {
    return Validators.validateTargetFile(_targetFile) == null &&
           (_flutterVersion.isEmpty || Validators.validateFlutterVersion(_flutterVersion) == null);
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _beginUpload() async {
    if (_selectedFile == null) return;
    setState(() {
      _isUploading = true;
      _uploadProgress = 'Preparing upload...';
      _uploadProgressValue = 0.0;
      _uploadId = null;
    });

    try {
      final repository = ref.read(buildRepositoryProvider);
      final id = await repository.uploadPickedFile(
        _selectedFile!,
        onProgress: (progress) {
          setState(() {
            _uploadProgressValue = progress;
            _uploadProgress = 'Uploading: ${(progress * 100).toInt()}%';
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _uploadId = id;
        _uploadProgressValue = 1.0;
        _uploadProgress = 'Upload complete (100%)';
        _isUploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _uploadProgress = '';
        _uploadProgressValue = 0.0;
        _uploadId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: LightModeColors.lightError,
        ),
      );
    }
  }

  Future<void> _createBuild() async {
    if (_isCreating) return;

    setState(() => _isCreating = true);

    try {
      final repository = ref.read(buildRepositoryProvider);

      // Ensure upload is completed for uploadZip
      if (_selectedSourceType == SourceType.uploadZip) {
        if (_uploadId == null || _uploadProgressValue < 1.0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please wait until the upload completes before creating the build.'),
                backgroundColor: LightModeColors.lightError,
              ),
            );
          }
          return;
        }
      }

      // Create build source
      final source = BuildSource(
        type: _selectedSourceType,
        uploadId: _selectedSourceType == SourceType.uploadZip ? _uploadId : null,
        // FlutterFlow structured fields
        ffProjectId: _selectedSourceType == SourceType.flutterFlow ? (_ffProjectId.isNotEmpty ? _ffProjectId : null) : null,
        ffEndpoint: _selectedSourceType == SourceType.flutterFlow ? (_ffEndpoint.isNotEmpty ? _ffEndpoint : null) : null,
        ffProjectEnvironment: _selectedSourceType == SourceType.flutterFlow ? (_ffEnvironment.isNotEmpty ? _ffEnvironment : null) : null,
        ffIncludeAssets: _selectedSourceType == SourceType.flutterFlow ? _ffIncludeAssets : null,
        ffToken: _selectedSourceType == SourceType.flutterFlow ? _ffToken : null,
        // Back-compat URL if available (not used in API payload but kept for state)
        ffUrl: _selectedSourceType == SourceType.flutterFlow ? (_ffUrl.isNotEmpty ? _ffUrl : null) : null,
        gitUrl: _selectedSourceType == SourceType.gitRepo ? _gitUrl : null,
        branch: _selectedSourceType != SourceType.uploadZip ? _branch : AppConstants.noBranch,
      );

      // Create build config
      final config = BuildConfig(
        flutterVersion: _flutterVersion.isEmpty ? AppConstants.defaultFlutterVersion : _flutterVersion,
        buildType: _buildType,
        targetFile: _targetFile,
        preSteps: _preSteps,
        postSteps: _postSteps,
        platforms: _platforms,
      );

      // Create the build job
      final request = CreateBuildRequest(source: source, config: config);
      final response = await repository.createBuild(request);

      // Navigate to job detail
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.jobCreatedSuccess),
            backgroundColor: LightModeColors.lightTertiary,
          ),
        );
        context.goToJobDetail(response.id);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create build: $error'),
            backgroundColor: LightModeColors.lightError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
          // Keep upload status visible; user may navigate back
        });
      }
    }
  }
}