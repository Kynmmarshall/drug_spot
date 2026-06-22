import 'package:intl/intl.dart';

import '../models/app_language.dart';
import '../models/user_type.dart';

class Localizer {
  Localizer(this.language);

  final AppLanguage language;

  static const Map<AppLanguage, Map<String, String>> _values = {
    AppLanguage.en: {
      'login_title': 'Find trusted pharmacies nearby',
      'login_subtitle':
          'Track live availability, compare prices, and reserve before you travel.',
      'login_user_type': 'Sign in as',
      'user_type_pharmacy': 'Pharmacy',
      'user_type_patient': 'Patient',
      'input_username': 'Username',
      'input_password': 'Password',
      'login_button': 'Continue',
      'login_register_prompt': 'New here?',
      'login_register_btn': 'Create an account',
      'register_title': 'Create your Drug Spot account',
      'register_subtitle':
          'Stay bilingual and location-aware for every prescription need.',
      'input_email': 'Email',
      'input_phone': 'Contact number',
      'input_confirm_password': 'Confirm password',
      'detect_location': 'Detect my position',
      'detecting_location': 'Detecting location...',
      'location_ready': 'Location detected',
      'register_button': 'Finish registration',
      'geolocation_hint':
          'We only use your coordinates to surface nearby pharmacies.',
      'pharmacy_dashboard_title': 'Pharmacy control room',
      'patient_dashboard_title': 'Patient dashboard',
      'stats_inventory': 'Managed meds',
      'stats_inventory_sub': 'Active catalog',
      'stats_requests': 'Open requests',
      'stats_requests_sub': 'Patient pings this week',
      'stats_coverage': 'Community reach',
      'stats_coverage_sub': 'Avg. delivery radius',
      'requests_screen_title': 'Patient requests',
      'requests_screen_subtitle':
          'Review every patient asking your pharmacy for a medicine.',
      'requests_screen_empty': 'No one has requested a medicine yet.',
      'requests_contact': 'Contact',
      'requests_medicine_label': 'Requested',
      'pharmacy_manage_title': 'Medicines you added',
      'pharmacy_manage_sub': 'Update price, stock & visibility',
      'map_title': 'Community map',
      'map_subtitle': 'Live view of verified pharmacies',
      'map_cta': 'Expand map',
      'map_legend': 'Tap a pin for more details',
      'community_map_intro':
          'Explore every verified pharmacy and gauge distance instantly.',
      'community_map_pharmacies': 'pharmacies mapped',
      'medicine_all_section': 'Entire marketplace',
      'patient_all_medicines': 'Available medicines',
      'medicine_details_title': 'Medicine details',
      'medicine_details_overview': 'Pricing & availability snapshot.',
      'medicine_details_distance': 'Distance from patient',
      'medicine_details_pharmacy': 'Pharmacy contact',
      'medicine_details_contact': 'Contact',
      'search_placeholder': 'Search a medicine name',
      'filter_distance': 'Distance filter',
      'filters': 'Filters',
      'empty_results': 'No medicine matches your filters yet.',
      'add_medicine': 'Add medicine',
      'update_medicine': 'Update medicine',
      'medicine_name': 'Medicine name',
      'medicine_price': 'Price (FCFA)',
      'assign_pharmacy': 'Pharmacy',
      'cancel': 'Cancel',
      'save': 'Save changes',
      'delete': 'Delete',
      'profile_title_pharmacy': 'Your pharmacy profile',
      'profile_title_patient': 'Your patient profile',
      'profile_subtitle_pharmacy': 'Build trust with rich details & imagery.',
      'profile_subtitle_patient': 'Share context for better care pathways.',
      'profile_bio': 'Bio / tagline',
      'profile_avatar': 'Avatar style',
      'profile_save': 'Save profile',
      'profile_picture': 'Profile photo',
      'profile_username_helper': 'Visible across dashboards.',
      'profile_phone_helper': 'WhatsApp-ready number preferred.',
      'my_medicines_title': 'My medicines',
      'my_medicines_empty': 'You have not published any medicines yet.',
      'my_medicines_empty_hint':
          'Use the button below to publish your first listing.',
      'dark_theme': 'Switch to dark theme',
      'light_theme': 'Switch to light theme',
      'distance_chip_nearby': 'Nearby',
      'distance_chip_affordable': 'Affordable',
      'distance_chip_popular': 'Popular meds',
      'login_form_error': 'Fill in your username and password to continue.',
      'error_username_required': 'Username is required',
      'error_password_min': 'Use at least 6 characters',
      'error_email': 'Enter a valid email',
      'error_phone': 'Contact number is required',
      'error_confirm_password': 'Passwords must match',
      'register_success': 'Account created! You can now sign in.',
      'med_created': 'Medicine added successfully.',
      'med_updated': 'Medicine updated successfully.',
      'med_deleted': 'Medicine removed.',
      'pharmacy_setup_title': 'Set up your pharmacy',
      'pharmacy_setup_welcome': 'Welcome, pharmacist!',
      'pharmacy_setup_subtitle':
          'Register your pharmacy so patients can find you on the map.',
      'pharmacy_setup_name': 'Pharmacy name',
      'pharmacy_setup_name_error': 'Pharmacy name is required',
      'pharmacy_setup_address': 'Street address',
      'pharmacy_setup_address_error': 'Address is required',
      'pharmacy_setup_location_hint':
          'Detect your pharmacy coordinates so patients can locate you.',
      'pharmacy_setup_location_required':
          'Please detect your location before submitting.',
      'pharmacy_setup_submit': 'Create pharmacy',
    },
    AppLanguage.fr: {
      'login_title': 'Trouvez une pharmacie fiable près de vous',
      'login_subtitle':
          'Suivez les stocks en direct, comparez les prix et réservez avant de partir.',
      'login_user_type': 'Se connecter en tant que',
      'user_type_pharmacy': 'Pharmacie',
      'user_type_patient': 'Patient',
      'input_username': "Nom d'utilisateur",
      'input_password': 'Mot de passe',
      'login_button': 'Continuer',
      'login_register_prompt': 'Nouveau sur la plateforme ?',
      'login_register_btn': 'Créer un compte',
      'register_title': 'Créez votre compte Drug Spot',
      'register_subtitle':
          'Restez bilingue et géolocalisé pour chaque ordonnance.',
      'input_email': 'Email',
      'input_phone': 'Numéro de contact',
      'input_confirm_password': 'Confirmez le mot de passe',
      'detect_location': 'Détecter ma position',
      'detecting_location': 'Détection en cours...',
      'location_ready': 'Localisation détectée',
      'register_button': "Terminer l'inscription",
      'geolocation_hint':
          'Nous utilisons vos coordonnées pour afficher les pharmacies proches.',
      'pharmacy_dashboard_title': 'Cockpit pharmacie',
      'patient_dashboard_title': 'Tableau patient',
      'stats_inventory': 'Médicaments gérés',
      'stats_inventory_sub': 'Catalogue actif',
      'stats_requests': 'Demandes ouvertes',
      'stats_requests_sub': 'Alertes patients cette semaine',
      'stats_coverage': 'Rayon communautaire',
      'stats_coverage_sub': 'Rayon moyen de livraison',
      'requests_screen_title': 'Demandes patients',
      'requests_screen_subtitle':
          'Consultez chaque patient qui attend un médicament chez vous.',
      'requests_screen_empty':
          'Aucun patient ne vous a encore demandé de médicament.',
      'requests_contact': 'Contact',
      'requests_medicine_label': 'Demande',
      'pharmacy_manage_title': 'Vos médicaments ajoutés',
      'pharmacy_manage_sub': 'Mettez à jour prix, stock et visibilité',
      'map_title': 'Carte communautaire',
      'map_subtitle': 'Vue des pharmacies vérifiées',
      'map_cta': 'Ouvrir la carte',
      'map_legend': 'Touchez une épingle pour les détails',
      'community_map_intro':
          "Explorez chaque pharmacie vérifiée et mesurez les distances en un coup d'oeil.",
      'community_map_pharmacies': 'pharmacies cartographiées',
      'medicine_all_section': 'Marché complet',
      'patient_all_medicines': 'Médicaments disponibles',
      'medicine_details_title': 'Détails du médicament',
      'medicine_details_overview': 'Aperçu sur le prix et la disponibilité.',
      'medicine_details_distance': 'Distance du patient',
      'medicine_details_pharmacy': 'Contact pharmacie',
      'medicine_details_contact': 'Contact',
      'search_placeholder': 'Rechercher un médicament',
      'filter_distance': 'Filtre de distance',
      'filters': 'Filtres',
      'empty_results': "Aucun médicament ne correspond à vos filtres.",
      'add_medicine': 'Ajouter un médicament',
      'update_medicine': 'Modifier le médicament',
      'medicine_name': 'Nom du médicament',
      'medicine_price': 'Prix (FCFA)',
      'assign_pharmacy': 'Pharmacie',
      'cancel': 'Annuler',
      'save': 'Enregistrer',
      'delete': 'Supprimer',
      'profile_title_pharmacy': 'Profil pharmacie',
      'profile_title_patient': 'Profil patient',
      'profile_subtitle_pharmacy':
          'Inspirez confiance avec des détails et visuels riches.',
      'profile_subtitle_patient':
          'Partagez votre contexte pour de meilleurs parcours de soin.',
      'profile_bio': 'Bio / slogan',
      'profile_avatar': "Style d'avatar",
      'profile_save': 'Enregistrer le profil',
      'profile_picture': 'Photo de profil',
      'profile_username_helper': 'Visible sur les tableaux.',
      'profile_phone_helper': 'Numéro WhatsApp recommandé.',
      'my_medicines_title': 'Mes médicaments',
      'my_medicines_empty': "Vous n'avez pas encore publié de médicament.",
      'my_medicines_empty_hint':
          'Utilisez le bouton ci-dessous pour créer votre première fiche.',
      'dark_theme': 'Passer en thème sombre',
      'light_theme': 'Passer en thème clair',
      'distance_chip_nearby': 'À proximité',
      'distance_chip_affordable': 'Abordable',
      'distance_chip_popular': 'Populaire',
      'login_form_error': "Renseignez votre nom d'utilisateur et mot de passe.",
      'error_username_required': "Nom d'utilisateur obligatoire",
      'error_password_min': '6 caractères minimum',
      'error_email': 'Email invalide',
      'error_phone': 'Numéro requis',
      'error_confirm_password': 'Les mots de passe doivent être identiques',
      'register_success': 'Compte créé ! Vous pouvez vous connecter.',
      'med_created': 'Médicament ajouté.',
      'med_updated': 'Médicament mis à jour.',
      'med_deleted': 'Médicament supprimé.',
      'pharmacy_setup_title': 'Configurez votre pharmacie',
      'pharmacy_setup_welcome': 'Bienvenue, pharmacien !',
      'pharmacy_setup_subtitle':
          'Enregistrez votre pharmacie pour que les patients vous trouvent sur la carte.',
      'pharmacy_setup_name': 'Nom de la pharmacie',
      'pharmacy_setup_name_error': 'Le nom est obligatoire',
      'pharmacy_setup_address': 'Adresse',
      'pharmacy_setup_address_error': "L'adresse est obligatoire",
      'pharmacy_setup_location_hint':
          'Détectez les coordonnées de votre pharmacie pour être localisable.',
      'pharmacy_setup_location_required':
          'Veuillez détecter votre position avant de soumettre.',
      'pharmacy_setup_submit': 'Créer la pharmacie',
    },
  };

  String t(String key) => _values[language]![key] ?? key;

  String userTypeLabel(UserType type) => type == UserType.pharmacy
      ? t('user_type_pharmacy')
      : t('user_type_patient');

  String distanceLabel(double km) => language == AppLanguage.en
      ? '${km.toStringAsFixed(0)} km radius'
      : '${km.toStringAsFixed(0)} km de rayon';

  String distanceAway(double km) => language == AppLanguage.en
      ? '${km.toStringAsFixed(1)} km away'
      : 'à ${km.toStringAsFixed(1)} km';

  String resultsCount(int count) =>
      language == AppLanguage.en ? '$count medicines' : '$count médicaments';

  String priceLabel(double price) {
    final formatter = NumberFormat.currency(
      locale: language == AppLanguage.en ? 'en_US' : 'fr_FR',
      symbol: 'FCFA ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }
}
