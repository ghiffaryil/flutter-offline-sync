// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names
import 'package:flutter/material.dart';
import 'sql_helper.dart';
import 'package:http/http.dart' as http;

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
  // All journals
  List<Map<String, dynamic>> _dataUser = [];

  bool _isLoading = true;
  // This function is used to fetch all data from the database
  void _refreshdata() async {
    // Mengambil fungsi get item dari SQL Helper
    final data = await SQLHelper.getItems();
    setState(() {
      _dataUser = data;
      _isLoading = false;
    });

    print('data =>' + data.toString());
  }

  @override
  void initState() {
    super.initState();
    _refreshdata(); // Loading the diary when the app starts
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  void syncdata() async {
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

    // PROSES INPUT DATA
    try {
      // Mengirim data _dataUser ke API PHP
      final response = await http.post(
        Uri.parse('http://192.168.1.11:1301/api/useroffline/create.php'),
        body: _dataUser.toString(),
        headers: {'Content-Type': 'application/json'},
      );

      // Menampilkan pesan sukses atau gagal
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sync completed successfully!'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sync failed!'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('An error occurred during sync!'),
      ));
    }
  }

  void _showForm(int? id) async {
    // id == null -> create new item
    // id != null -> update an existing item
    if (id != null) {
      final existingJournal =
          _dataUser.firstWhere((element) => element['id'] == id);
      _titleController.text = existingJournal['title'];
      _descriptionController.text = existingJournal['description'];
    } else {
      _titleController.text = '';
      _descriptionController.text = '';
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
                bottom: MediaQuery.of(context).viewInsets.bottom + 120,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: 'Title'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(hintText: 'Description'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (id == null) {
                        // Menjalankan fungsi Add Item
                        await _addItem();
                      }

                      if (id != null) {
                        // Menjalankan fungsi Update Item
                        await _updateItem(id);
                      }

                      // Menghapus Inputan
                      _titleController.text = '';
                      _descriptionController.text = '';

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
    // Mengambil fungsi dari SQL Helper
    await SQLHelper.createItem(
        _titleController.text, _descriptionController.text);
    _refreshdata();
  }

  // Update Item
  Future<void> _updateItem(int id) async {
    // Mengambil fungsi dari SQL Helper
    await SQLHelper.updateItem(
        id, _titleController.text, _descriptionController.text);
    _refreshdata();
  }

  // Hapus item
  void _deleteItem(int id) async {
    // Mengambil fungsi dari SQL Helper
    await SQLHelper.deleteItem(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Successfully deleted a journal!'),
    ));
    _refreshdata();
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Offline Sync'),
        actions: [
          IconButton(
              onPressed: () {
                syncdata();
              },
              icon: const Icon(Icons.sync))
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: _dataUser.length,
              itemBuilder: (context, index) => Card(
                color: Colors.orange[200],
                margin: const EdgeInsets.all(15),
                child: ListTile(
                    title: Text("${_dataUser[index]['title']}"),
                    subtitle: Text(_dataUser[index]['description']),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showForm(_dataUser[index]['id']),
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
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }
}
