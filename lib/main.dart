import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:safe_yt_flutter/api.dart';
import 'package:safe_yt_flutter/config.dart';
import 'package:safe_yt_flutter/video_list.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const App());
}


class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe YT',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const AppHome(),
    );
  }
}

class AppHome extends StatefulWidget {
  const AppHome({super.key});
  
  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {

  List<VideoItem> _videos = [];
  bool _isLoading = true;
  int _page = 1;
  String? _error;

  final Api api = Api();
  final Config _config = Config();

  String? _apiUrl;
  bool _promptVisible = false;

  @override
  void initState() {
    super.initState();
    _loadApiUrl();
  }

  Future<void> _loadApiUrl() async {
    final url = await _config.getApiUrl();
    if (!mounted) return;
    if (url == null || url.isEmpty) {
      // No API URL configured: prompt the user to add one.
      setState(() {
        _isLoading = false;
        _promptVisible = true;
      });
      return;
    }
    setState(() => _apiUrl = url);
    await _fetchVideos();
  }

  Future<void> _saveApiUrl(String url) async {
    final normalized = url.trim().replaceAll(RegExp(r'/+$'), '');
    await _config.setApiUrl(normalized);
    if (!mounted) return;
    setState(() {
      _apiUrl = normalized;
      _videos = [];
      _page = 1;
      _error = null;
      _isLoading = true;
      _promptVisible = false;
    });
    await _fetchVideos();
  }

  void _editApiUrl() {
    setState(() {
      _promptVisible = true;
      _error = null;
    });
  }

  // Paganation
  Future<void> _loadMore() async {
    _page += 1;
    await _fetchVideos();
  }

  Future<void> _showPinsScreen() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewPins()
      )
    );
  }
  Future<void> _fetchVideos() async {
    final videos = await api.getVideos(_page);
    if (!mounted) return; // Always check if widget is still in the tree
    if (videos == null) {
      setState(() {
        _error = 'Could not load videos from $_apiUrl';
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _videos = [..._videos, ...videos];
      _error = null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_promptVisible || _apiUrl == null) {
      return ApiUrlPrompt(
        initialValue: _apiUrl,
        onSubmit: _saveApiUrl,
        onCancel: _apiUrl == null
            ? null
            : () => setState(() => _promptVisible = false),
      );
    }
    // Use Scaffold for proper background, theme, and layout handling
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe YT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.push_pin),
            tooltip: 'Pins',
            onPressed: _showPinsScreen
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'API settings',
            onPressed: _editApiUrl,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                  _fetchVideos();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return VideoList(videos: _videos, loadMore: _loadMore,);
  }
}


class ViewPins extends StatefulWidget {
  const ViewPins({super.key});
  
  @override
  State<ViewPins> createState() => _ViewPinsState();
}

class _ViewPinsState extends State<ViewPins> {

  List<VideoItem> _videos = [];
  bool _isLoading = true;
  int _page = 1;
  String? _error;

  final Api api = Api();

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  // Paganation
  Future<void> _loadMore() async {
    _page += 1;
    await _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    final videos = await api.getVideos(_page, "pins");
    if (!mounted) return; // Always check if widget is still in the tree
    if (videos == null) {
      setState(() {
        _error = 'Could not load videos.';
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _videos = [..._videos, ...videos];
      _error = null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use Scaffold for proper background, theme, and layout handling
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pins')
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                  _fetchVideos();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return VideoList(videos: _videos, loadMore: _loadMore,);
  }
}


class ApiUrlPrompt extends StatefulWidget {
  const ApiUrlPrompt({
    super.key,
    required this.onSubmit,
    this.initialValue,
    this.onCancel,
  });

  final ValueChanged<String> onSubmit;
  final String? initialValue;
  final VoidCallback? onCancel;

  @override
  State<ApiUrlPrompt> createState() => _ApiUrlPromptState();
}

class _ApiUrlPromptState extends State<ApiUrlPrompt> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Please enter an API URL');
      return;
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      setState(() => _error = 'Enter a valid URL, e.g. https://example.com');
      return;
    }
    widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add an API URL to get started',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'API URL',
                    hintText: 'https://example.com',
                    errorText: _error,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Save'),
                ),
                if (widget.onCancel != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}



