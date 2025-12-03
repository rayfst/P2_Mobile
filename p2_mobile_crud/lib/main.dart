import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'db/db_202310321_202310011.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    sqflite.databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

/// TEMA SKYLINE (blueAccent + lightBlue)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData skylineTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blueAccent,
      ).copyWith(
        primary: Colors.blueAccent,
        secondary: Colors.lightBlue,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(12),
          ),
        ),
        elevation: 2,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );

    return MaterialApp(
      title: 'Mini Cadastro de Tarefas',
      debugShowCheckedModeBanner: false,
      theme: skylineTheme,
      home: const TaskListPage(),
    );
  }
}

/// TELA DE LISTAGEM (ListView.builder)
class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _dbHelper.getAllTasks();
    setState(() {
      _tasks = tasks;
    });
  }

  Future<void> _deleteTask(Task task) async {
    if (task.id != null) {
      await _dbHelper.deleteTask(task.id!);
      await _loadTasks();
    }
  }

  Future<void> _openTaskForm({Task? task}) async {
    final result = await Navigator.of(context).push<Task?>(
      MaterialPageRoute(
        builder: (_) => TaskFormPage(task: task),
      ),
    );

    if (result != null) {
      await _loadTasks();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Color _priorityColor(int prioridade) {
    switch (prioridade) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.deepOrange;
      case 5:
      default:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarefas Profissionais'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlue, Colors.blueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _tasks.isEmpty
            ? const Center(
                child: Text(
                  'Nenhuma tarefa cadastrada ainda.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
            : ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  /// FUNÇÃO DE DELETAR
                  return Dismissible(
                    key: ValueKey(task.id ?? index),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.redAccent,
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Excluir tarefa'),
                              content: const Text(
                                  'Tem certeza de que deseja excluir esta tarefa?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(true),
                                  child: const Text('Excluir'),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                    },
                    onDismissed: (_) => _deleteTask(task),
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        onTap: () => _openTaskForm(task: task),
                        leading: CircleAvatar(
                          backgroundColor: _priorityColor(task.prioridade),
                          child: Text(
                            task.prioridade.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(task.titulo),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (task.descricao.isNotEmpty)
                              Text(task.descricao),
                            const SizedBox(height: 4),
                            Text(
                              'Criado em: ${_formatDate(task.criadoEm)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Prioridade cliente: ${task.prioridadeCliente}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _openTaskForm(task: task),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// TELA DE FORMULÁRIO (INSERIR / EDITAR)
class TaskFormPage extends StatefulWidget {
  final Task? task;

  const TaskFormPage({super.key, this.task});

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priorityClientController;
  int _prioridade = 3;

  @override
  void initState() {
    super.initState();
    final task = widget.task;

    _titleController = TextEditingController(text: task?.titulo ?? '');
    _descriptionController =
        TextEditingController(text: task?.descricao ?? '');
    _priorityClientController =
        TextEditingController(text: task?.prioridadeCliente ?? '');
    _prioridade = task?.prioridade ?? 3;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priorityClientController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final titulo = _titleController.text.trim();
    final descricao = _descriptionController.text.trim();
    final prioridadeCliente = _priorityClientController.text.trim();

    final isEditing = widget.task != null;

    final task = Task(
      id: widget.task?.id,
      titulo: titulo,
      descricao: descricao,
      prioridade: _prioridade,
      criadoEm: widget.task?.criadoEm ?? DateTime.now(),
      prioridadeCliente: prioridadeCliente,
    );

    if (isEditing) {
      await _dbHelper.updateTask(task);
    } else {
      await _dbHelper.insertTask(task);
    }

    if (mounted) {
      Navigator.of(context).pop(task);
    }
  }

    /// FUNÇÃO DE DELETAR TASK DENTRO DE EDITAR
    Future<void> _deleteTask() async {
    if (widget.task?.id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir tarefa'),
        content: const Text(
            'Tem certeza de que deseja excluir esta tarefa? Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _dbHelper.deleteTask(widget.task!.id!);
      if (mounted) {
        Navigator.of(context).pop(widget.task);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Tarefa' : 'Nova Tarefa'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteTask,
              tooltip: 'Excluir tarefa',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ex: Reunião com o cliente',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o título da tarefa';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Detalhes da tarefa',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _prioridade,
                decoration: const InputDecoration(
                  labelText: 'Prioridade (1 = baixa, 5 = muito alta)',
                ),
                items: List.generate(
                  5,
                  (index) {
                    final value = index + 1;
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value.toString()),
                    );
                  },
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _prioridade = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priorityClientController,
                decoration: const InputDecoration(
                  labelText: 'Prioridade do Cliente',
                  hintText: 'Ex: Cliente VIP, contrato novo, etc.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a prioridade do cliente';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveTask,
                  icon: const Icon(Icons.save),
                  label: Text(isEditing ? 'Salvar alterações' : 'Cadastrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}