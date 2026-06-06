import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const WindowLayoutApp());

class WindowLayoutApp extends StatelessWidget {
  const WindowLayoutApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '窗口布局管理', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true, brightness: Brightness.dark),
    home: const LayoutHomePage(),
  );
}

class LayoutPreset {
  String id, name;
  List<LayoutZone> zones;
  LayoutPreset({required this.id, required this.name, required this.zones});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'zones': zones.map((z) => z.toJson()).toList()};
  factory LayoutPreset.fromJson(Map<String, dynamic> j) => LayoutPreset(id: j['id'], name: j['name'], zones: (j['zones'] as List).map((z) => LayoutZone.fromJson(z)).toList());
}

class LayoutZone {
  double x, y, w, h;
  String label;
  LayoutZone({required this.x, required this.y, required this.w, required this.h, this.label = ''});
  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'w': w, 'h': h, 'label': label};
  factory LayoutZone.fromJson(Map<String, dynamic> j) => LayoutZone(x: j['x'].toDouble(), y: j['y'].toDouble(), w: j['w'].toDouble(), h: j['h'].toDouble(), label: j['label'] ?? '');
}

class LayoutHomePage extends StatefulWidget {
  const LayoutHomePage({super.key});
  @override
  State<LayoutHomePage> createState() => _LayoutHomePageState();
}

class _LayoutHomePageState extends State<LayoutHomePage> {
  List<LayoutPreset> _presets = [];
  LayoutPreset? _active;
  int? _dragIndex;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final d = p.getString('layout_presets');
    if (d != null) { setState(() => _presets = (json.decode(d) as List).map((e) => LayoutPreset.fromJson(e)).toList()); }
    else {
      _presets = [
        LayoutPreset(id: '1', name: '左右分屏', zones: [LayoutZone(x: 0, y: 0, w: 0.5, h: 1, label: '左'), LayoutZone(x: 0.5, y: 0, w: 0.5, h: 1, label: '右')]),
        LayoutPreset(id: '2', name: '三栏布局', zones: [LayoutZone(x: 0, y: 0, w: 0.33, h: 1, label: '左'), LayoutZone(x: 0.33, y: 0, w: 0.34, h: 1, label: '中'), LayoutZone(x: 0.67, y: 0, w: 0.33, h: 1, label: '右')]),
        LayoutPreset(id: '3', name: '四宫格', zones: [LayoutZone(x: 0, y: 0, w: 0.5, h: 0.5, label: '左上'), LayoutZone(x: 0.5, y: 0, w: 0.5, h: 0.5, label: '右上'), LayoutZone(x: 0, y: 0.5, w: 0.5, h: 0.5, label: '左下'), LayoutZone(x: 0.5, y: 0.5, w: 0.5, h: 0.5, label: '右下')]),
        LayoutPreset(id: '4', name: '主侧布局', zones: [LayoutZone(x: 0, y: 0, w: 0.65, h: 1, label: '主窗口'), LayoutZone(x: 0.65, y: 0, w: 0.35, h: 1, label: '侧边栏')]),
      ];
      _save();
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('layout_presets', json.encode(_presets.map((e) => e.toJson()).toList()));
  }

  void _apply(LayoutPreset preset) {
    setState(() => _active = preset);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已应用布局: ${preset.name}'), behavior: SnackBarBehavior.floating));
  }

  void _addPreset() {
    final nameC = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('新建布局'),
      content: TextField(controller: nameC, decoration: const InputDecoration(labelText: '布局名称', border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () {
          if (nameC.text.isNotEmpty) {
            final preset = LayoutPreset(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameC.text, zones: [LayoutZone(x: 0, y: 0, w: 1, h: 1, label: '全屏')]);
            setState(() { _presets.add(preset); _active = preset; });
            _save();
          }
          Navigator.pop(ctx);
        }, child: const Text('创建')),
      ],
    ));
  }

  void _editPreset(LayoutPreset preset) {
    final nameC = TextEditingController(text: preset.name);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('编辑布局'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, decoration: const InputDecoration(labelText: '布局名称', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        const Text('区域配置:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...preset.zones.asMap().entries.map((e) => ListTile(dense: true, leading: Text('${e.key + 1}'), title: Text('${e.value.label} (${(e.value.w * 100).toInt()}% x ${(e.value.h * 100).toInt()}%)'))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () { setState(() => preset.name = nameC.text); _save(); Navigator.pop(ctx); }, child: const Text('保存')),
      ],
    ));
  }

  void _deletePreset(LayoutPreset preset) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('删除布局'), content: Text('删除「${preset.name}」？'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')), FilledButton(onPressed: () { setState(() { _presets.removeWhere((p) => p.id == preset.id); if (_active?.id == preset.id) _active = null; }); _save(); Navigator.pop(ctx); }, child: const Text('删除'))],
    ));
  }

  void _splitZone(LayoutPreset preset, int index, bool horizontal) {
    final zone = preset.zones[index];
    setState(() {
      preset.zones.removeAt(index);
      if (horizontal) {
        preset.zones.insert(index, LayoutZone(x: zone.x, y: zone.y, w: zone.w / 2, h: zone.h, label: '${zone.label}-左'));
        preset.zones.insert(index + 1, LayoutZone(x: zone.x + zone.w / 2, y: zone.y, w: zone.w / 2, h: zone.h, label: '${zone.label}-右'));
      } else {
        preset.zones.insert(index, LayoutZone(x: zone.x, y: zone.y, w: zone.w, h: zone.h / 2, label: '${zone.label}-上'));
        preset.zones.insert(index + 1, LayoutZone(x: zone.x, y: zone.y + zone.h / 2, w: zone.w, h: zone.h / 2, label: '${zone.label}-下'));
      }
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🪟 窗口布局管理'), centerTitle: true, actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _addPreset, tooltip: '新建布局'),
      ]),
      body: Column(children: [
        // 布局预览
        if (_active != null) Container(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('当前布局: ${_active!.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          AspectRatio(aspectRatio: 16 / 9, child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)), child: Stack(children: _active!.zones.asMap().entries.map((e) {
            final colors = [Colors.blue.shade100, Colors.green.shade100, Colors.orange.shade100, Colors.purple.shade100, Colors.red.shade100, Colors.teal.shade100];
            return Positioned(left: e.value.x * MediaQuery.of(context).size.width * 0.9, top: e.value.y * 180, width: e.value.w * MediaQuery.of(context).size.width * 0.9, height: e.value.h * 180, child: Container(margin: const EdgeInsets.all(2), decoration: BoxDecoration(color: colors[e.key % colors.length], borderRadius: BorderRadius.circular(4)), child: Center(child: Text(e.value.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))));
          }).toList()))),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => _editPreset(_active!), icon: const Icon(Icons.edit), label: const Text('编辑'))),
            const SizedBox(width: 8),
            Expanded(child: FilledButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('布局已应用到系统'), behavior: SnackBarBehavior.floating)), icon: const Icon(Icons.check), label: const Text('应用'))),
          ]),
        ])),
        const Divider(height: 1),
        // 预设列表
        Expanded(child: _presets.isEmpty ? const Center(child: Text('点击 + 创建布局', style: TextStyle(color: Colors.grey))) : ListView.builder(padding: const EdgeInsets.all(12), itemCount: _presets.length, itemBuilder: (ctx, i) {
          final p = _presets[i];
          final isActive = _active?.id == p.id;
          return Card(color: isActive ? Theme.of(context).colorScheme.primaryContainer : null, margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            leading: Icon(isActive ? Icons.check_circle : Icons.grid_view, color: isActive ? Theme.of(context).colorScheme.primary : null),
            title: Text(p.name, style: TextStyle(fontWeight: isActive ? FontWeight.bold : null)),
            subtitle: Text('${p.zones.length} 个区域'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.content_cut, size: 20), onPressed: () => showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Padding(padding: EdgeInsets.all(12), child: Text('选择区域分割', style: TextStyle(fontWeight: FontWeight.bold))),
                ...p.zones.asMap().entries.map((e) => ListTile(title: Text(e.value.label), trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  TextButton(onPressed: () { Navigator.pop(ctx); _splitZone(p, e.key, true); }, child: const Text('垂直分割')),
                  TextButton(onPressed: () { Navigator.pop(ctx); _splitZone(p, e.key, false); }, child: const Text('水平分割')),
                ]))),
              ])), tooltip: '分割区域'),
              IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editPreset(p), tooltip: '编辑'),
              IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: () => _deletePreset(p), tooltip: '删除'),
            ]),
            onTap: () => _apply(p),
          ));
        })),
      ]),
    );
  }
}
