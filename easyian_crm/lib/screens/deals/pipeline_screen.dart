// lib/screens/deals/pipeline_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/desktop_widgets.dart';

class PipelineScreen extends StatelessWidget {
  const PipelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      Expanded(
        child: Column(
          children: [
            const PageHeader(
              title: 'Pipeline',
              subtitle: 'Manage deals by stage',
            ),
            Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            const Expanded(
              child: EmptyState(
                icon: Icons.view_kanban_outlined,
                title: 'No pipeline data yet',
                subtitle: 'Create your first pipeline to get started',
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}
