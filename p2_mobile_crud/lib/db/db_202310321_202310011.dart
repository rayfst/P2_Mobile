import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// MODELO DE TAREFA
class Task {
  int? id;
  String titulo;
  String descricao;
  int prioridade;
  DateTime criadoEm;
  String prioridadeCliente;

  Task({
    this.id,
    required this.titulo,
    required this.descricao,
    required this.prioridade,
    required this.criadoEm,
    required this.prioridadeCliente,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'titulo': titulo,
      'descricao': descricao,
      'prioridade': prioridade,
      'criadoEm': criadoEm.toIso8601String(),
      'prioridadeCliente': prioridadeCliente,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      titulo: map['titulo'] ?? '',
      descricao: map['descricao'] ?? '',
      prioridade: (map['prioridade'] ?? 0) as int,
      criadoEm: DateTime.tryParse(map['criadoEm']?.toString() ?? '') ??
          DateTime.now(),
      prioridadeCliente: map['prioridadeCliente']?.toString() ?? '',
    );
  }
}

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  static const String _dbName = 'tarefas_RA202310321_202310011.db';
  static const int _dbVersion = 1;
  static const String tableTasks = 'tasks';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = p.join(dir.path, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableTasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        descricao TEXT,
        prioridade INTEGER,
        criadoEm TEXT,
        prioridadeCliente TEXT
      )
    ''');
  }

  // CRUD

  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert(tableTasks, task.toMap());
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final maps = await db.query(
      tableTasks,
      orderBy: 'criadoEm DESC',
    );
    return maps.map((e) => Task.fromMap(e)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      tableTasks,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      tableTasks,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
