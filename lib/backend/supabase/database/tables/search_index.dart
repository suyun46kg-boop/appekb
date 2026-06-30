import '../database.dart';

class SearchIndexTable extends SupabaseTable<SearchIndexRow> {
  @override
  String get tableName => 'search_index';

  @override
  SearchIndexRow createRow(Map<String, dynamic> data) => SearchIndexRow(data);
}

class SearchIndexRow extends SupabaseDataRow {
  SearchIndexRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SearchIndexTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get title => getField<String>('title');
  set title(String? value) => setField<String>('title', value);
}
