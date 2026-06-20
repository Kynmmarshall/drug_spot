import 'package:flutter/widgets.dart';

import 'app_state.dart';
import 'localizer.dart';

extension BuildContextX on BuildContext {
  AppState get appState => AppStateScope.of(this);

  Localizer get l10n => appState.localizer;
}
