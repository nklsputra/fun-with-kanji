import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fun_with_kanji/config/app_constants.dart';
import 'package:fun_with_kanji/models/fun_with_kanji.dart';
import 'package:fun_with_kanji/pages/settings/settings_view.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fun_with_kanji/utils/open_issue_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  SettingsController createState() => SettingsController();
}

class SettingsController extends State<SettingsPage> {
  late final Future<SharedPreferences> preferencesFuture;

  @override
  void initState() {
    preferencesFuture = SharedPreferences.getInstance();
    super.initState();
  }

  void resetLearningProgressAction() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context)!.areYouSure),
        content: Text(L10n.of(context)!.resetLearningProgress),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop<bool>(false),
            child: Text(
              L10n.of(context)!.cancel,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyText2?.color,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop<bool>(true),
            child: Text(
              L10n.of(context)!.reset,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (result != true) return;
    await FunWithKanji.of(context).resetLearningProgress();
  }

  void openWebsite() => launch(AppConstants.website);

  void displayAboutDialog() => showAboutDialog(
        context: context,
        applicationName: AppConstants.appName,
      );

  void exportAction() async {
    try {
      final export = await FunWithKanji.of(context).export();
      final exportStr = await compute(jsonEncode, export);
      final file = FilePickerCross(Uint8List.fromList(exportStr.codeUnits));
      await file.exportToStorage(
        fileName:
            'fun_with_kanji_export_${DateTime.now().toIso8601String()}.json',
        share: false,
      );
    } catch (e, s) {
      showOpenIssueDialog(context, e, s);
      rethrow;
    }
  }

  void importAction() async {
    final picked = await FilePickerCross.importFromStorage(
      type: FileTypeCross.custom,
      fileExtension: 'json',
    );
    final path = picked.path;
    if (path == null) return;
    try {
      final jsonStr = picked.toString();
      final json = await compute(jsonDecode, jsonStr);
      await FunWithKanji.of(context).import(Map<String, dynamic>.from(json));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(L10n.of(context)!.importFinished),
      ));
    } catch (e, s) {
      showOpenIssueDialog(context, e, s);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) => SettingsView(this);
}
