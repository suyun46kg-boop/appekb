import '../database.dart';

class CaruselTable extends SupabaseTable<CaruselRow> {
  @override
  String get tableName => 'carusel';

  @override
  CaruselRow createRow(Map<String, dynamic> data) => CaruselRow(data);
}

class CaruselRow extends SupabaseDataRow {
  CaruselRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CaruselTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get images => getField<String>('images');
  set images(String? value) => setField<String>('images', value);

  String? get links => getField<String>('links');
  set links(String? value) => setField<String>('links', value);
}
