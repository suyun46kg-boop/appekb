import '../database.dart';

class CategoriesTable extends SupabaseTable<CategoriesRow> {
  @override
  String get tableName => 'categories';

  @override
  CategoriesRow createRow(Map<String, dynamic> data) => CategoriesRow(data);
}

class CategoriesRow extends SupabaseDataRow {
  CategoriesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CategoriesTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  int get id1 => getField<int>('id1')!;
  set id1(int value) => setField<int>('id1', value);

  /// null = корневая категория; иначе id1 родителя.
  int? get parentId1 => getField<int>('parent_id1');
  set parentId1(int? value) => setField<int>('parent_id1', value);

  bool get isRoot => parentId1 == null;
}
