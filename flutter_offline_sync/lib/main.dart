// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, prefer_interpolation_to_compose_strings, unused_local_variable, avoid_print
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'sql_helper_2.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        // Remove the debug banner
        debugShowCheckedModeBanner: false,
        title: 'FLUTTER OFFLINE SYNC',
        theme: ThemeData(
          primarySwatch: Colors.orange,
        ),
        home: const HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _dataUser = [];
  bool _isLoading = true;

  void _refreshData() async {
    // CEK APAKAH ADA DATABASE?
    if (!(await SQLHelper.isTableExists())) {
      await SQLHelper.createTables(SQLHelper.database!);
    }

    final data = await SQLHelper.getItem();

    setState(() {
      _dataUser = data;
      _isLoading = false;
    });

    print(_dataUser);
  }

  void initDatabase() async {
    SQLHelper.database = await SQLHelper.initDatabase();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    initDatabase();
    _refreshData();
  }

  final TextEditingController _namaUserController = TextEditingController();
  final TextEditingController _alamatUserController = TextEditingController();

  void syncdata() async {
    if (_dataUser.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tidak ada data yang perlu di-sinkronisasi!'),
      ));
    } else {
      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              content: SizedBox(
            height: MediaQuery.of(context).size.height * 0.20,
            width: MediaQuery.of(context).size.width * 0.20,
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(
                  height: 20,
                ),
                Text('Syncing ...')
              ],
            )),
          ));
        },
      );
      try {
        // Ubah List _dataUser menjadi Json
        String dataUserJson = json.encode(_dataUser);
        print('jsonData => ' + dataUserJson);
        // Mengirim data _dataUser ke API PHP
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://192.168.1.11:1301/api/useroffline/syncdata.php'),
        );

        // Set the content-type header
        request.headers['Content-Type'] = 'multipart/form-data';

        // Add the data_json_user field as part of the multipart request
        request.fields['data_json_user'] = dataUserJson;

        // Send the multipart request
        var response = await request.send();

        // Read and decode the response
        var responseBody = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseBody);
        var status = jsonResponse['Status'];
        var keterangan = jsonResponse['Keterangan'];
        print(status);
        print(keterangan);

        // Menampilkan pesan sukses atau gagal
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Sinkronisasi ke database berhasil!'),
          ));

          // HAPUS ALL ITEM
          setState(() {
            _dataUser = [];
          });
          // HAPUS SEMUA DATA YANG SUDAH DI-SINKRONKAN
          await SQLHelper.deleteAllItems();

          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Sinkronisasi ke database gagal!'),
          ));
          Navigator.pop(context);
        }
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ada masalah dalam sinkronisasi!'),
        ));
        Navigator.pop(context);
      }

      setState(() {
        _refreshData();
      });
    }
  }

  void _showForm(int? id) async {
    // id == null -> create new item
    // id != null -> update an existing item
    if (id != null) {
      final existingJournal =
          _dataUser.firstWhere((element) => element['id'] == id);
      _namaUserController.text = existingJournal['nama_user'];
      _alamatUserController.text = existingJournal['alamat'];
    } else {
      _namaUserController.text = '';
      _alamatUserController.text = '';
    }
    showModalBottomSheet(
        context: context,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
              padding: EdgeInsets.only(
                top: 15,
                left: 15,
                right: 15,
                // this will prevent the soft keyboard from covering the text fields
                bottom: MediaQuery.of(context).viewInsets.bottom + 80,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _namaUserController,
                    decoration: const InputDecoration(hintText: 'Nama'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _alamatUserController,
                    decoration: const InputDecoration(hintText: 'Alamat'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Jika id = null maka Menjalankan fungsi Add Item
                      if (id == null) {
                        await _addItem();
                      }
                      if (id != null) {
                        // Jika id = ada maka Menjalankan fungsi Update Item
                        await _updateItem(id);
                      }
                      // Menghapus Inputan
                      _namaUserController.text = '';
                      _alamatUserController.text = '';
                      // Tutup Modal
                      Navigator.of(context).pop();
                    },
                    child: Text(id == null ? 'Create New' : 'Update'),
                  )
                ],
              ),
            ));
  }

  // Add New Item
  Future<void> _addItem() async {
    await SQLHelper.addItem(
        _namaUserController.text, _alamatUserController.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Data berhasil ditambahkan!'),
    ));
    _refreshData();
  }

  // Update Item
  Future<void> _updateItem(int id) async {
    await SQLHelper.updateItem(
        id, _namaUserController.text, _alamatUserController.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Data Terupdate!'),
    ));
    _refreshData();
  }

  // Delete item
  void _deleteItem(int id) async {
    await SQLHelper.deleteItem(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Data Terhapus!'),
    ));
    _refreshData();
  }

  // HAPUS TABLE
  void _deleteTable() async {
    await SQLHelper.deleteTable();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Tabel terhapus!'),
    ));
    _refreshData();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              syncdata();
            },
            icon: const Icon(Icons.sync)),
        title: const Text('Flutter Offline Sync'),
        actions: [
          IconButton(
              onPressed: () {
                _deleteTable();
              },
              icon: const Icon(Icons.delete)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView.builder(
                itemCount: _dataUser.length,
                itemBuilder: (context, index) => Card(
                  color: Colors.orange[200],
                  margin: const EdgeInsets.all(15),
                  child: ListTile(
                      title: Text("${_dataUser[index]['nama_user']}"),
                      subtitle: Text(_dataUser[index]['alamat']),
                      trailing: SizedBox(
                        width: 100,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _showForm(_dataUser[index]['id']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  _deleteItem(_dataUser[index]['id']),
                            ),
                          ],
                        ),
                      )),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }
}
