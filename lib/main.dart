import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:safe_yt_flutter/api.dart';
import 'package:safe_yt_flutter/config.dart';
import 'package:safe_yt_flutter/video.dart';

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
    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. The Video Grid
          Padding(
            padding: const EdgeInsets.all(10.0), // Give it some breathing room
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _videos.map((video) => VideoEntry(video: video)).toList(),
            ),
          ),

          // 2. The Load More button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton.filled(
                onPressed: _loadMore,
                icon: const Icon(Icons.expand_more),
                tooltip: "Load more",
                iconSize: 50,
              ),
            ),
          ),
        ],
      ),
    );
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



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.red),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  Future<void> _incrementCounter() async {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
