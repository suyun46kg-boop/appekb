

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
