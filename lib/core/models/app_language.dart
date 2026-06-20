enum AppLanguage { en, fr }

extension AppLanguageX on AppLanguage {
  String get code => this == AppLanguage.en ? 'en' : 'fr';

  String get label => this == AppLanguage.en ? 'English' : 'Français';

  String get shortLabel => this == AppLanguage.en ? 'EN' : 'FR';
}
