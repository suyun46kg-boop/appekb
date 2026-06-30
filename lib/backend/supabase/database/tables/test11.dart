import '../database.dart';

class Test11Table extends SupabaseTable<Test11Row> {
  @override
  String get tableName => 'test11';

  @override
  Test11Row createRow(Map<String, dynamic> data) => Test11Row(data);
}

class Test11Row extends SupabaseDataRow {
  Test11Row(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => Test11Table();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get name1 => getField<String>('name1');
  set name1(String? value) => setField<String>('name1', value);

  String? get name2 => getField<String>('name2');
  set name2(String? value) => setField<String>('name2', value);

  String? get name3 => getField<String>('name3');
  set name3(String? value) => setField<String>('name3', value);
}
