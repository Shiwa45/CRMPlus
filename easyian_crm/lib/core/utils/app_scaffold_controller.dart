import 'package:flutter/material.dart';

class AppScaffoldController {
  AppScaffoldController._();

  static final GlobalKey<ScaffoldState> rootScaffoldKey = GlobalKey<ScaffoldState>();

  static void openDrawer() => rootScaffoldKey.currentState?.openDrawer();
  static void closeDrawer() => rootScaffoldKey.currentState?.closeDrawer();
}
