import 'package:supabase_flutter/supabase_flutter.dart';

String getFriendlyErrorMessage(dynamic error) {
  if (error == null) return 'Une erreur inconnue est survenue.';

  // If it's a Supabase Auth Exception
  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Email ou mot de passe incorrect.';
    } else if (msg.contains('email already in use') ||
        msg.contains('email already registered')) {
      return 'Cet email est déjà associé à un compte.';
    } else if (msg.contains('password should be') ||
        msg.contains('at least 6 characters')) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    } else if (msg.contains('invalid email') ||
        msg.contains('invalid format')) {
      return 'L\'adresse email saisie n\'est pas valide.';
    } else if (msg.contains('user not found')) {
      return 'Aucun utilisateur trouvé avec cet email.';
    } else if (msg.contains('weak password')) {
      return 'Le mot de passe choisi est trop faible.';
    } else if (msg.contains('network') ||
        msg.contains('socketexception') ||
        msg.contains('clientexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection refused') ||
        msg.contains('connection closed') ||
        msg.contains('handshakeexception')) {
      return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
    } else if (msg.contains('invalid api key') || msg.contains('apikey')) {
      return 'Configuration serveur invalide. Vérifiez la clé Supabase.';
    }
    return error.message;
  }

  // If it's a Supabase Database/Postgrest Exception
  if (error is PostgrestException) {
    final msg = error.message.toLowerCase();
    final details = error.details?.toString().toLowerCase() ?? '';

    if (msg.contains('violates row-level security policy') ||
        msg.contains('row-level security')) {
      return 'Accès refusé. Vous n\'avez pas les permissions nécessaires.';
    } else if (msg.contains('violates unique constraint') ||
        details.contains('already exists') ||
        msg.contains('duplicate key')) {
      return 'Cette valeur existe déjà dans le système (doublon non autorisé).';
    } else if (msg.contains('violates foreign key constraint') ||
        details.contains('is not present in table')) {
      return 'Erreur de liaison : la ressource associée n\'existe pas.';
    } else if (msg.contains('violates not-null constraint') ||
        msg.contains('null value in column')) {
      return 'Un champ obligatoire requis par la base de données est manquant.';
    } else if (msg.contains('invalid input syntax') ||
        msg.contains('invalid input')) {
      return 'Format de données incorrect pour la base de données.';
    }
    return error.message;
  }

  // General errors
  final String message = error.toString().toLowerCase();

  if (message.contains('network') ||
      message.contains('socketexception') ||
      message.contains('clientexception') ||
      message.contains('failed host lookup') ||
      message.contains('connection refused') ||
      message.contains('connection closed') ||
      message.contains('handshakeexception')) {
    return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
  } else if (message.contains('invalid api key') ||
      message.contains('apikey')) {
    return 'Configuration serveur invalide. Vérifiez la clé Supabase.';
  } else if (message.contains('timeout')) {
    return 'Le délai d\'attente est dépassé. Veuillez réessayer.';
  } else if (message.contains('permission denied') ||
      message.contains('permission_denied')) {
    return 'Permission refusée.';
  } else if (message.contains('invalid login credentials')) {
    return 'Email ou mot de passe incorrect.';
  } else if (message.contains('email already in use')) {
    return 'Cet email est déjà utilisé.';
  } else if (message.contains('weak password')) {
    return 'Le mot de passe est trop faible.';
  }

  // Remove "Exception: " or "FormatException: " prefixes for cleaner display
  String cleanMsg = error.toString();
  if (cleanMsg.startsWith('Exception: ')) {
    cleanMsg = cleanMsg.substring(11);
  } else if (cleanMsg.startsWith('FormatException: ')) {
    cleanMsg = cleanMsg.substring(17);
  }

  return cleanMsg;
}
