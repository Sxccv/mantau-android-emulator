import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Diperlukan agar DateFormat('...', 'id_ID') tidak melempar galat.
  await initializeDateFormatting('id_ID', null);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MantauApp(),
    ),
  );
}
