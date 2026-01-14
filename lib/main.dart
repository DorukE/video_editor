import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_editor/video_editor.dart';

void main() => runApp(const MaterialApp(
  home: VideoPickerPage(),
  debugShowCheckedModeBanner: false,
));

// --- GÜZELLEŞTİRİLMİŞ GİRİŞ EKRANI ---
class VideoPickerPage extends StatelessWidget {
  const VideoPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1E26), Color(0xFF000000)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.movie_filter, color: Colors.blueAccent, size: 80),
            ),
            const SizedBox(height: 30),
            const Text(
              "Video Editor Pro",
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 10),
            const Text(
              "Harika videolar oluşturmaya başla",
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 60),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 10,
                shadowColor: Colors.blueAccent.withOpacity(0.5),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 26),
              label: const Text("YENİ PROJE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () async {
                final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
                if (file != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => VideoEditorPage(file: File(file.path))),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class VideoEditorPage extends StatefulWidget {
  final File file;
  const VideoEditorPage({super.key, required this.file});

  @override
  State<VideoEditorPage> createState() => _VideoEditorPageState();
}

class _VideoEditorPageState extends State<VideoEditorPage> {
  late final VideoEditorController _controller;
  bool _isInitialized = false;
  bool _showSpeed = false;
  double _currentSpeed = 1.0;

  // Filtre ve Metin Değişkenleri
  Color _selectedFilterColor = Colors.transparent;
  BlendMode _selectedBlendMode = BlendMode.dst;
  String _videoText = "";
  Offset _textPosition = const Offset(150, 200);
  double _textScale = 1.0;
  double _initialScale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = VideoEditorController.file(
      widget.file,
      minDuration: const Duration(milliseconds: 100),
      maxDuration: const Duration(minutes: 60),
    );

    _controller.initialize().then((_) {
      if (mounted) setState(() => _isInitialized = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- SIFIRLA: Timeline dahil her şeyi ilk güne döndürür ---
  void _resetAll() {
    setState(() {
      _currentSpeed = 1.0;
      _controller.video.setPlaybackSpeed(1.0);
      _selectedFilterColor = Colors.transparent;
      _selectedBlendMode = BlendMode.dst;
      _videoText = "";
      _textScale = 1.0;
      // Timeline sıfırlama (Kırpılan yerleri açar)
      _controller.updateTrim(0.0, 1.0);
      _controller.video.seekTo(Duration.zero);
      _showSpeed = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tüm ayarlar ve Timeline sıfırlandı!"), duration: Duration(seconds: 1)),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 180,
          child: Column(
            children: [
              const Text("Filtreler", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterIcon("Normal", Colors.transparent, BlendMode.dst, Icons.refresh),
                    _filterIcon("Sıcak", Colors.orange.withOpacity(0.4), BlendMode.softLight, Icons.wb_sunny),
                    _filterIcon("Soğuk", Colors.blue.withOpacity(0.4), BlendMode.softLight, Icons.wb_cloudy),
                    _filterIcon("Retro", Colors.brown.withOpacity(0.5), BlendMode.overlay, Icons.grain),
                    _filterIcon("S&B", Colors.black.withOpacity(0.7), BlendMode.saturation, Icons.contrast),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterIcon(String name, Color color, BlendMode mode, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilterColor = color;
            _selectedBlendMode = mode;
          });
          Navigator.pop(context);
        },
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color == Colors.transparent ? Colors.white12 : color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueAccent, width: 2),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // --- METİN GİRİŞİ ---
  void _showTextInput() {
    TextEditingController textEntry = TextEditingController(text: _videoText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Metin Yaz", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: textEntry,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "Video üzerine yazı...", hintStyle: TextStyle(color: Colors.white24)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () {
              setState(() => _videoText = textEntry.text);
              Navigator.pop(context);
            },
            child: const Text("Tamam"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitialized
          ? SafeArea(
        child: Column(
            children: [
        Expanded(
        child: Stack(
        fit: StackFit.expand,
            children: [
        // VIDEO VE GERÇEK FILTRE KATMANI
        Center(
        child: ColorFiltered(
        colorFilter: ColorFilter.mode(_selectedFilterColor, _selectedBlendMode),
        child: GestureDetector(
          onTap: () => setState(() {
            _controller.video.value.isPlaying ? _controller.video.pause() : _controller.video.play();
          }),
          child: CropGridViewer.preview(controller: _controller),
        ),
      ),
    ),

    // SÜRÜKLENEBİLİR VE ÖLÇEKLENEBİLİR (BÜYÜTÜLEBİLİR) METİN
    if (_videoText.isNotEmpty)
    Positioned(
    left: _textPosition.dx,
    top: _textPosition.dy,
    child: GestureDetector(
    onScaleStart: (details) {
    _initialScale = _textScale;
    },
    onScaleUpdate: (details) {
    setState(() {
    // İki parmakla büyütme (zoom)
    _textScale = (_initialScale * details.scale).clamp(0.5, 8.0);
    // Tek parmakla sürükleme
    _textPosition += details.focalPointDelta;
    });
    },
    child: Transform.scale(
    scale: _textScale,
    child: Container(
    padding: const EdgeInsets.all(10),
    child: Text(
    _videoText,
    style: const TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    shadows: [Shadow(color: Colors.black, blurRadius: 12, offset: Offset(2, 2))],
    ),
    ),
    ),
    ),
    ),
    ),
    ],
    ),
    ),

    // TİMELİNE
    Container(
    height: 100,
    width: double.infinity,
    color: const Color(0xFF0F0F0F),
    child: TrimSlider(
    controller: _controller,
    height: 60,
    horizontalMargin: 20,
    ),
    ),

    if (_showSpeed)
    Container(
    color: const Color(0xFF1A1A1A),
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
    child: Row(
    children: [
    const Icon(Icons.speed, color: Colors.blueAccent),
    Expanded(
    child: Slider(
    value: _currentSpeed, min: 0.5, max: 2.0,
    onChanged: (v) => setState(() {
    _currentSpeed = v;
    _controller.video.setPlaybackSpeed(v);
    }),
    ),
    ),
    Text("${_currentSpeed.toStringAsFixed(1)}x", style: const TextStyle(color: Colors.blueAccent)),
    ],
    ),
    ),

    // ALT ARAÇLAR
    Container(
    height: 85,
    color: const Color(0xFF1A1A1A),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
    _tool(Icons.av_timer, "Hız", () => setState(() => _showSpeed = !_showSpeed)),
    _tool(Icons.filter_vintage, "Filtre", _showFilterOptions),
    _tool(Icons.text_fields, "Metin", _showTextInput),
    _tool(Icons.history, "Sıfırla", _resetAll),
    _tool(Icons.close, "Kapat", () => Navigator.pop(context)),
    ],
    ),
    ),
    ],
    ),
    )
        : const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
    );
  }

  Widget _tool(IconData icon, String label, VoidCallback action) {
    return InkWell(
      onTap: action,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}