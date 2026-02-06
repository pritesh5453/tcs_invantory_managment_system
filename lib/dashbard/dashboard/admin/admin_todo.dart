import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class TodoPage extends StatefulWidget {
  final int userId;
  final String role;
  final String section;

  const TodoPage({
    super.key,
    required this.userId,
    required this.role,
    this.section = 'General',
  });

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final Dio _dio = Dio();
  final TextEditingController _titleController = TextEditingController();

  bool isLoading = false;
  List<dynamic> todoList = [];

  @override
  void initState() {
    super.initState();
    fetchTodos();
  }

  // ---------------- CREATE TODO ----------------
  Future<void> createTodo() async {
    if (_titleController.text.trim().isEmpty) return;

    try {
      setState(() => isLoading = true);

      final response = await _dio.post(
        'https://dashboard.theceramicstudio.in/api/todo/CreateTodo',
        data: {
          "title": _titleController.text.trim(),
          "section": widget.section,
          "userId": widget.userId,
          "role": widget.role,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _titleController.clear();
        fetchTodos();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created successfully')),
        );
      }
    } catch (e) {
      debugPrint('Create Todo Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ---------------- GET ALL TODO ----------------
  Future<void> fetchTodos() async {
    try {
      setState(() => isLoading = true);

      final response = await _dio.get(
        'https://dashboard.theceramicstudio.in/api/todo/getTodo',
        queryParameters: {"role": widget.role, "section": widget.section},
      );

      if (response.statusCode == 200) {
        setState(() {
          todoList = response.data;
        });
      }
    } catch (e) {
      debugPrint('Fetch Todo Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ---------------- DELETE TODO ----------------
  Future<void> deleteTodo(int id) async {
    try {
      await _dio.delete(
        'https://dashboard.theceramicstudio.in/api/todo/Delete/$id',
      );

      fetchTodos();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted successfully')),
      );
    } catch (e) {
      debugPrint('Delete Todo Error: $e');
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('My Todo', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // -------- CREATE TODO SECTION --------
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Enter task title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: isLoading ? null : createTodo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ),

          // -------- TODO LIST --------
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : todoList.isEmpty
                    ? const Center(child: Text('No Todos Found'))
                    : ListView.builder(
                      itemCount: todoList.length,
                      itemBuilder: (context, index) {
                        final todo = todoList[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(todo['title']),
                            subtitle: Text(
                              'Status: ${todo['status']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteTodo(todo['id']),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
