/// Uma instituição/filial marcada como favorita pelo utilizador -- tabela
/// `favorites` no Supabase (ver
/// `fila-certa-staff/supabase/migrations/20260908120000_guest_mode_and_favorites.sql`).
class Favorite {
  final String institutionId;
  final String branchId;

  const Favorite({required this.institutionId, required this.branchId});

  @override
  bool operator ==(Object other) =>
      other is Favorite && other.institutionId == institutionId && other.branchId == branchId;

  @override
  int get hashCode => Object.hash(institutionId, branchId);
}
