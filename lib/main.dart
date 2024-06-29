import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(AplikasiSaya());
}

class AplikasiSaya extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notepad Cepat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HalamanDaftarCatatan(),
    );
  }
}

class HalamanDaftarCatatan extends StatefulWidget {
  @override
  _HalamanDaftarCatatanState createState() => _HalamanDaftarCatatanState();
}

class _HalamanDaftarCatatanState extends State<HalamanDaftarCatatan> {
  List<Map<String, String>> _catatan = [];
  List<Map<String, String>> _catatanTersaring = [];

  @override
  void initState() {
    super.initState();
    _muatCatatan();
  }

  Future<void> _muatCatatan() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> catatanString = prefs.getStringList('catatan') ?? [];
    List<Map<String, String>> catatan = catatanString.map((item) {
      List<String> splitItem = item.split('|');
      return {
        'konten': splitItem[0],
        'tanggal': splitItem[1],
      };
    }).toList();
    setState(() {
      _catatan = catatan;
      _catatanTersaring = catatan;
    });
  }

  Future<void> _simpanCatatan() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> catatanString =
        _catatan.map((item) => '${item['konten']}|${item['tanggal']}').toList();
    prefs.setStringList('catatan', catatanString);
  }

  Future<void> _tambahCatatan() async {
    Map<String, String>? catatanBaru = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HalamanEditorCatatan()),
    );
    if (catatanBaru != null) {
      setState(() {
        _catatan.add(catatanBaru);
        _catatanTersaring = _catatan;
      });
      _simpanCatatan();
    }
  }

  Future<void> _editCatatan(int indeks) async {
    final catatanEdit = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => HalamanEditorCatatan(
          catatan: _catatanTersaring[indeks]['konten']!,
          tanggal: _catatanTersaring[indeks]['tanggal']!,
        ),
      ),
    );
    if (catatanEdit != null) {
      setState(() {
        int indeksAsli = _catatan.indexOf(_catatanTersaring[indeks]);
        _catatan[indeksAsli] = catatanEdit;
        _catatanTersaring[indeks] = catatanEdit;
      });
      await _simpanCatatan();
    }
  }

  Future<void> _hapusCatatan(int indeks) async {
    setState(() {
      int indeksAsli = _catatan.indexOf(_catatanTersaring[indeks]);
      _catatan.removeAt(indeksAsli);
      _catatanTersaring = _catatan; // Menggunakan _catatan sebagai referensi
    });
    await _simpanCatatan();
  }

  void _saringCatatan(String query) {
    setState(() {
      if (query.isEmpty) {
        _catatanTersaring = _catatan;
      } else {
        _catatanTersaring = _catatan
            .where((catatan) =>
                catatan['konten']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Notes'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: DelegasiPencarianCatatan(_catatan),
              ).then((query) {
                if (query != null) {
                  _saringCatatan(query);
                }
              });
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _catatanTersaring.length,
        itemBuilder: (context, indeks) {
          return GestureDetector(
            onLongPress: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Hapus Catatan'),
                    content:
                        Text('Apakah Anda yakin ingin menghapus catatan ini?'),
                    actions: [
                      TextButton(
                        child: Text('Batal'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text('Hapus'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _hapusCatatan(indeks);
                        },
                      ),
                    ],
                  );
                },
              );
            },
            onTap: () => _editCatatan(indeks),
            child: ListTile(
              title: Text(_catatanTersaring[indeks]['konten']!),
              subtitle: Text(_catatanTersaring[indeks]['tanggal']!),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tambahCatatan,
        child: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

class DelegasiPencarianCatatan extends SearchDelegate {
  final List<Map<String, String>> catatan;

  DelegasiPencarianCatatan(this.catatan);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final hasil = catatan
        .where((catatan) =>
            catatan['konten']!.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: hasil.length,
      itemBuilder: (context, indeks) {
        return ListTile(
          title: Text(hasil[indeks]['konten']!),
          subtitle: Text(hasil[indeks]['tanggal']!),
          onTap: () {
            close(context, hasil[indeks]['konten']);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final saran = catatan
        .where((catatan) =>
            catatan['konten']!.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: saran.length,
      itemBuilder: (context, indeks) {
        return ListTile(
          title: Text(saran[indeks]['konten']!),
          subtitle: Text(saran[indeks]['tanggal']!),
          onTap: () {
            query = saran[indeks]['konten']!;
            showResults(context);
          },
        );
      },
    );
  }
}

class HalamanEditorCatatan extends StatefulWidget {
  final String catatan;
  final String tanggal;

  HalamanEditorCatatan({this.catatan = '', this.tanggal = ''});

  @override
  _HalamanEditorCatatanState createState() => _HalamanEditorCatatanState();
}

class _HalamanEditorCatatanState extends State<HalamanEditorCatatan> {
  late TextEditingController _pengontrol;

  @override
  void initState() {
    super.initState();
    _pengontrol = TextEditingController(text: widget.catatan);
  }

  @override
  void dispose() {
    _pengontrol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.catatan.isEmpty ? 'Tambah Catatan' : 'Edit Catatan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _pengontrol,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Tulis catatan Anda di sini...',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                String catatan = _pengontrol.text;
                String tanggal = widget.tanggal.isEmpty
                    ? DateFormat('dd-MM-yyyy – kk:mm').format(DateTime.now())
                    : widget.tanggal;
                Navigator.pop(context, {'konten': catatan, 'tanggal': tanggal});
              },
              child: Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
