import 'package:flutter/material.dart';
import '../models/queue_location.dart';
import '../theme/app_theme.dart';

/// Categoria de instituição (marca): verde-menta para instituições
/// públicas (hoje só o SIAC), âmbar para instituições em geral (bancos).
/// Deliberadamente simples -- só 2 categorias, porque é tudo o que o
/// catálogo real (`mock_data.dart`) hoje distingue; mais categorias só
/// fariam sentido com mais tipos de instituição parceira.
enum InstitutionCategory { publicService, bank }

InstitutionCategory categoryOf(QueueLocation location) =>
    location.institutionId == 'siac' ? InstitutionCategory.publicService : InstitutionCategory.bank;

extension InstitutionCategoryX on InstitutionCategory {
  String get label => switch (this) {
        InstitutionCategory.publicService => 'serviço público',
        InstitutionCategory.bank => 'banco',
      };

  Color get color => switch (this) {
        InstitutionCategory.publicService => AppColors.mint,
        InstitutionCategory.bank => AppColors.amber,
      };

  Color get background => switch (this) {
        InstitutionCategory.publicService => AppColors.mintBg,
        InstitutionCategory.bank => AppColors.amberBg,
      };

  Color get onDark => switch (this) {
        InstitutionCategory.publicService => AppColors.onMintDark,
        InstitutionCategory.bank => AppColors.onAmberDark,
      };
}
