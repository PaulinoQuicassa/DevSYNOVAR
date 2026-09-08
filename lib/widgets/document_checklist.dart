import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// "O que preciso levar?" (secção 13 do redesign) -- objectivo: evitar
/// que o cidadão espere numa fila e descubra depois que não pode
/// concluir o serviço. Lista de referência, não uma garantia contratual
/// (por isso o aviso final está sempre presente).
class DocumentChecklist extends StatefulWidget {
  final List<String> documents;

  const DocumentChecklist({super.key, required this.documents});

  @override
  State<DocumentChecklist> createState() => _DocumentChecklistState();
}

class _DocumentChecklistState extends State<DocumentChecklist> {
  late final Set<int> _checked = {};

  @override
  Widget build(BuildContext context) {
    if (widget.documents.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Antes de sair, confirme se tem:', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          ...List.generate(widget.documents.length, (i) {
            final checked = _checked.contains(i);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                onTap: () => setState(() => checked ? _checked.remove(i) : _checked.add(i)),
                child: Row(
                  children: [
                    Icon(
                      checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      size: 20,
                      color: checked ? AppColors.success : AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.documents[i],
                        style: TextStyle(
                          fontSize: 13,
                          color: checked ? AppColors.textSecondary : AppColors.textPrimary,
                          decoration: checked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 15, color: AppColors.warning),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Confirme os documentos exactos junto da instituição antes de entrar na fila.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
