import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../data/models/retail_models.dart';
import '../controllers/retail_controller.dart';
import '../../../pos/data/models/pos_models.dart';
import '../../../pos/presentation/controllers/pos_controller.dart';

class RetailDraftsPage extends StatefulWidget { const RetailDraftsPage({super.key}); @override State<RetailDraftsPage> createState() => _RetailDraftsPageState(); }
class _RetailDraftsPageState extends State<RetailDraftsPage> { @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) context.read<RetailController>().loadDrafts(); }); } @override Widget build(BuildContext context) { final retail = context.watch<RetailController>(); if (retail.loadingDrafts && retail.drafts.isEmpty) return const AppLoadingState(message: 'Cargando cobros pendientes…'); return RefreshIndicator(onRefresh: () => retail.loadDrafts(force: true), child: ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [Row(children: [IconButton(onPressed: () => context.go('/app/retail/floor'), icon: const Icon(Icons.arrow_back)), const SizedBox(width: 8), Expanded(child: Text('Cola de cobros Retail', style: Theme.of(context).textTheme.headlineSmall)), IconButton.outlined(onPressed: () => retail.loadDrafts(force: true), icon: const Icon(Icons.refresh))]), const SizedBox(height: 12), DropdownButtonFormField<RetailDraftStatus?>(initialValue: retail.draftStatusFilter, decoration: const InputDecoration(labelText: 'Estado'), items: [const DropdownMenuItem(value: null, child: Text('Todos')), for(final state in RetailDraftStatus.values) DropdownMenuItem(value: state, child: Text(_draftLabel(state)))], onChanged: retail.setDraftStatusFilter), const SizedBox(height: 16), if (retail.errorMessage case final error?) Text(error, style: const TextStyle(color: AppColors.destructive)), if (retail.drafts.isEmpty) const OperationalEmptyState(title: 'Sin cobros pendientes', message: 'Los drafts creados desde probadores aparecerán aquí.') else for(final draft in retail.drafts) _DraftCard(draft: draft)])); } }
class _DraftCard extends StatelessWidget {
	const _DraftCard({required this.draft});

	final RetailDraft draft;

	@override
	Widget build(BuildContext context) {
		return Card(
			margin: const EdgeInsets.only(bottom: 12),
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Row(
							children: [
								Expanded(
									child: Text(
										draft.clientName,
										style: Theme.of(context).textTheme.titleMedium,
									),
								),
								Chip(label: Text(_draftLabel(draft.status))),
							],
						),
						Text(
							'Atendió: ${draft.sellerName} · ${draft.posCartDraft.length} partidas',
						),
						const SizedBox(height: 8),
						for (final item in draft.posCartDraft)
							Text(
								'${item.quantity} × ${item.name} · '
								'${AppFormatters.currency(item.unitPrice)}',
							),
						const Divider(),
						Row(
							children: [
								Text(
									AppFormatters.currency(draft.total),
									style: Theme.of(context).textTheme.titleLarge,
								),
								const Spacer(),
								if (draft.status == RetailDraftStatus.pending)
									TextButton(
										onPressed: () => context
												.read<RetailController>()
												.cancelDraft(draft.draftId),
										child: const Text('Cancelar'),
									),
								if (draft.status == RetailDraftStatus.pending)
									FilledButton.icon(
										onPressed: () {
											final lines = draft.posCartDraft
													.map(
														(item) => CartLine(
															product: PosProduct(
																id: item.productId,
																name: item.name,
																sku: item.sku,
																salePrice: item.unitPrice,
																unitName: 'pieza',
																category: 'Retail',
																stockOnHand: item.quantity,
																availableStock: item.quantity,
															),
															quantity: item.quantity,
														),
													)
													.toList(growable: false);
											context
													.read<PosController>()
													.loadRetailDraft(draft.draftId, lines);
											context.go('/app/pos/checkout');
										},
										icon: const Icon(Icons.point_of_sale_outlined),
										label: const Text('Cobrar'),
									),
							],
						),
					],
				),
			),
		);
	}
}
String _draftLabel(RetailDraftStatus status) => switch(status) {RetailDraftStatus.pending=>'Pendiente', RetailDraftStatus.consumed=>'Cobrado', RetailDraftStatus.cancelled=>'Cancelado'};
