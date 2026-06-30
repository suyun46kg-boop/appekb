import '../database.dart';

class ListingsTable extends SupabaseTable<ListingsRow> {
  @override
  String get tableName => 'listings';

  @override
  ListingsRow createRow(Map<String, dynamic> data) => ListingsRow(data);
}

class ListingsRow extends SupabaseDataRow {
  ListingsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ListingsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get title => getField<String>('title');
  set title(String? value) => setField<String>('title', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  double? get price => getField<double>('price');
  set price(double? value) => setField<double>('price', value);

  String? get city => getField<String>('city');
  set city(String? value) => setField<String>('city', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get img => getField<String>('img');
  set img(String? value) => setField<String>('img', value);

  int? get categoryId => getField<int>('category_id');
  set categoryId(int? value) => setField<int>('category_id', value);

  String? get phonnumber => getField<String>('phonnumber');
  set phonnumber(String? value) => setField<String>('phonnumber', value);

  String? get categoryName => getField<String>('category_name');
  set categoryName(String? value) => setField<String>('category_name', value);

  int? get paginationId => getField<int>('pagination_id');
  set paginationId(int? value) => setField<int>('pagination_id', value);

  String? get userName => getField<String>('user_name');
  set userName(String? value) => setField<String>('user_name', value);
}
