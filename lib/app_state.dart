import 'package:flutter/material.dart';
import '/backend/api_requests/api_manager.dart';
import 'backend/supabase/supabase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'dart:convert';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenWelcome = prefs.getBool('ff_hasSeenWelcome') ?? false;
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  bool _hasSeenWelcome = false;
  bool get hasSeenWelcome => _hasSeenWelcome;
  set hasSeenWelcome(bool value) {
    _hasSeenWelcome = value;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool('ff_hasSeenWelcome', value));
  }

  String _emailstate = '';
  String get emailstate => _emailstate;
  set emailstate(String value) {
    _emailstate = value;
  }

  String _searchText = '';
  String get searchText => _searchText;
  set searchText(String value) {
    _searchText = value;
  }

  bool _showSuggestionsBooltrue = true;
  bool get showSuggestionsBooltrue => _showSuggestionsBooltrue;
  set showSuggestionsBooltrue(bool value) {
    _showSuggestionsBooltrue = value;
  }

  String _tetxtsearchgrid = '';
  String get tetxtsearchgrid => _tetxtsearchgrid;
  set tetxtsearchgrid(String value) {
    _tetxtsearchgrid = value;
  }

  bool _gridshow = false;
  bool get gridshow => _gridshow;
  set gridshow(bool value) {
    _gridshow = value;
  }

  bool _categorysearchsow = false;
  bool get categorysearchsow => _categorysearchsow;
  set categorysearchsow(bool value) {
    _categorysearchsow = value;
  }

  String _dropvalue = '';
  String get dropvalue => _dropvalue;
  set dropvalue(String value) {
    _dropvalue = value;
  }

  dynamic _dropvalue2;
  dynamic get dropvalue2 => _dropvalue2;
  set dropvalue2(dynamic value) {
    _dropvalue2 = value;
  }

  String _dropvalue3 = '';
  String get dropvalue3 => _dropvalue3;
  set dropvalue3(String value) {
    _dropvalue3 = value;
  }

  String _valuecategoryshit = '';
  String get valuecategoryshit => _valuecategoryshit;
  set valuecategoryshit(String value) {
    _valuecategoryshit = value;
    notifyListeners();
  }

  int _idcategorysheet = 0;
  int get idcategorysheet => _idcategorysheet;
  set idcategorysheet(int value) {
    _idcategorysheet = value;
    notifyListeners();
  }

  String _emtytext = 'ечего не возможного';
  String get emtytext => _emtytext;
  set emtytext(String value) {
    _emtytext = value;
  }

  String _testidstate = '';
  String get testidstate => _testidstate;
  set testidstate(String value) {
    _testidstate = value;
  }

  bool _hhhverif = false;
  bool get hhhverif => _hhhverif;
  set hhhverif(bool value) {
    _hhhverif = value;
  }

  bool _hh1 = false;
  bool get hh1 => _hh1;
  set hh1(bool value) {
    _hh1 = value;
  }

  int _lastid = 0;
  int get lastid => _lastid;
  set lastid(int value) {
    _lastid = value;
  }

  String _test1 = '';
  String get test1 => _test1;
  set test1(String value) {
    _test1 = value;
  }

  int _lastid1 = 0;
  int get lastid1 => _lastid1;
  set lastid1(int value) {
    _lastid1 = value;
  }

  List<dynamic> _items = [];
  List<dynamic> get items => _items;
  set items(List<dynamic> value) {
    _items = value;
  }

  void addToItems(dynamic value) {
    items.add(value);
  }

  void removeFromItems(dynamic value) {
    items.remove(value);
  }

  void removeAtIndexFromItems(int index) {
    items.removeAt(index);
  }

  void updateItemsAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    items[index] = updateFn(_items[index]);
  }

  void insertAtIndexInItems(int index, dynamic value) {
    items.insert(index, value);
  }

  int _scrol80 = 0;
  int get scrol80 => _scrol80;
  set scrol80(int value) {
    _scrol80 = value;
  }
}
