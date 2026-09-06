import 'package:supabase_flutter/supabase_flutter.dart';

/// Projecto Supabase real (qdfpqispcntitvczybfl) -- mesmo projecto do
/// repo irmão `fila-certa-staff` (ver docs/migration-plan.md lá). A
/// "publishable key" não é secreta -- o controlo de acesso vive nas
/// políticas RLS (docs/security.md), não na chave.
const supabaseUrl = 'https://qdfpqispcntitvczybfl.supabase.co';
const supabaseAnonKey = 'sb_publishable_HLelr-FOPvSL9a5w8_feUw_FfKIrOoQ';

SupabaseClient get supabaseClient => Supabase.instance.client;
