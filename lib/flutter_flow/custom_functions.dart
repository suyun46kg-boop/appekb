import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/supabase/supabase.dart';
import '/auth/supabase_auth/auth_util.dart';

String touppercase(String stringvalue) {
  return stringvalue.toUpperCase();
}

bool? chekphonenumber(String phone) {
  return phone.length == 10;
}

bool? passlenth(String pass) {
  return pass.length >= 8;
}

bool fotoisempty(String image) {
  return image.isEmpty;
}
