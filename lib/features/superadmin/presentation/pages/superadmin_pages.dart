import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../data/models/superadmin_models.dart';
import '../controllers/superadmin_controller.dart';
import '../widgets/superadmin_dialogs.dart';

class SuperadminDashboardPage extends StatefulWidget {
  const SuperadminDashboardPage({super.key});

  @override
  State<SuperadminDashboardPage> createState() =>
      _SuperadminDashboardPageState();
}

class _SuperadminDashboardPageState extends State<SuperadminDashboardPage> {
  @override
  void initState() {
    super.initState();
    final controller = context.read<SuperadminController>();
    if (controller.tenants.isEmpty) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SuperadminController>();
    if (controller.loading && controller.tenants.isEmpty) {
      return const AppLoadingState(message: 'Cargando plataforma…');
    }
    if (controller.errorMessage case final message?
        when controller.tenants.isEmpty) {
      return AppErrorState(message: message, onRetry: controller.load);
    }

    final active = controller.tenants
        .where((tenant) => tenant.status == 'ACTIVE')
        .length;
    final branches = controller.tenants.fold<int>(
      0,
      (total, tenant) => total + tenant.branches.length,
    );
    final optionalModules = controller.tenants.fold<int>(
      0,
      (total, tenant) =>
          total +
          tenant.modules
              .where(
                (module) => module.isEnabled && module.moduleCode != 'CORE',
              )
              .length,
    );
    final statusCounts = <String, int>{};
    for (final tenant in controller.tenants) {
      statusCounts.update(
        tenant.status,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    return _SuperadminPageFrame(
      children: [
        PageHeader(
          title: 'Resumen de plataforma',
          subtitle:
              'Datos actuales reportados por la API de Superadmin para ${controller.tenants.length} tenants cargados.',
          actions: [
            IconButton(
              tooltip: 'Actualizar',
              onPressed: controller.loading ? null : controller.load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: constraints.maxWidth >= 1050 ? 4 : 2,
            childAspectRatio: constraints.maxWidth >= 1050 ? 1.7 : 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              MetricCard(
                label: 'Tenants totales',
                value: '${controller.tenantPage.total}',
                detail: '${controller.tenants.length} cargados',
                icon: Icons.business,
              ),
              MetricCard(
                label: 'Activos',
                value: '$active',
                detail: 'En el resultado cargado',
                icon: Icons.verified_outlined,
                color: AppColors.success,
              ),
              MetricCard(
                label: 'Sucursales',
                value: '$branches',
                detail: 'Reportadas por la API',
                icon: Icons.store_outlined,
                color: AppColors.tenantAccent,
              ),
              MetricCard(
                label: 'Módulos opcionales',
                value: '$optionalModules',
                detail: 'RETAIL y RESTAURANT activos',
                icon: Icons.extension_outlined,
                color: AppColors.info,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Distribución por estado',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              if (statusCounts.isEmpty)
                const Text('La API no devolvió tenants.')
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final entry in statusCounts.entries)
                      Chip(
                        avatar: Icon(
                          Icons.circle,
                          size: 12,
                          color: _tenantStatusColor(entry.key),
                        ),
                        label: Text(
                          '${_tenantStatusLabel(entry.key)} · ${entry.value}',
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class SuperadminTenantsPage extends StatefulWidget {
  const SuperadminTenantsPage({super.key});

  @override
  State<SuperadminTenantsPage> createState() => _SuperadminTenantsPageState();
}

class _SuperadminTenantsPageState extends State<SuperadminTenantsPage> {
  final _searchController = TextEditingController();
  String? _status;

  @override
  void initState() {
    super.initState();
    final controller = context.read<SuperadminController>();
    _searchController.text = controller.search;
    _status = controller.statusFilter;
    if (controller.tenants.isEmpty) controller.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() => context.read<SuperadminController>().load(
    search: _searchController.text,
    status: _status,
  );

  Future<void> _createTenant() async {
    final payload = await showTenantFormDialog(context);
    if (payload == null || !mounted) return;
    final controller = context.read<SuperadminController>();
    final success = await controller.createTenant(payload);
    if (!mounted) return;
    _showOperationResult(
      context,
      success: success,
      successMessage: 'Tenant creado correctamente.',
      errorMessage: controller.errorMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SuperadminController>();
    return _SuperadminPageFrame(
      children: [
        PageHeader(
          title: 'Tenants',
          subtitle: 'Gestiona las organizaciones registradas en el backend.',
          actions: [
            ElevatedButton.icon(
              onPressed: controller.saving ? null : _createTenant,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo tenant'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 360,
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _search(),
                decoration: const InputDecoration(
                  hintText: 'Nombre, slug o correo…',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String?>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Activo')),
                  DropdownMenuItem(value: 'PAUSED', child: Text('Pausado')),
                  DropdownMenuItem(
                    value: 'SUSPENDED',
                    child: Text('Suspendido'),
                  ),
                  DropdownMenuItem(value: 'BLOCKED', child: Text('Bloqueado')),
                ],
                onChanged: (value) => setState(() => _status = value),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: controller.loading ? null : _search,
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Aplicar'),
            ),
            IconButton(
              tooltip: 'Actualizar',
              onPressed: controller.loading ? null : _search,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (controller.loading)
          const LinearProgressIndicator()
        else if (controller.errorMessage case final message?)
          AppErrorState(message: message, onRetry: _search)
        else if (controller.tenants.isEmpty)
          OperationalEmptyState(
            title: 'No hay tenants que coincidan',
            message: 'Modifica los filtros o registra un tenant nuevo.',
            actionLabel: 'Limpiar filtros',
            onAction: () {
              _searchController.clear();
              setState(() => _status = null);
              _search();
            },
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Tenant')),
                  DataColumn(label: Text('Correo principal')),
                  DataColumn(label: Text('Plan')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Sucursales')),
                  DataColumn(label: Text('Módulos activos')),
                  DataColumn(label: Text('')),
                ],
                rows: [
                  for (final tenant in controller.tenants)
                    DataRow(
                      cells: [
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tenant.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(tenant.slug),
                            ],
                          ),
                        ),
                        DataCell(Text(tenant.primaryEmail)),
                        DataCell(Text(tenant.planCode)),
                        DataCell(_TenantStatus(status: tenant.status)),
                        DataCell(Text('${tenant.branches.length}')),
                        DataCell(Text('${tenant.enabledModuleCount}')),
                        DataCell(
                          IconButton(
                            tooltip: 'Ver tenant',
                            onPressed: () =>
                                context.go('/superadmin/tenants/${tenant.id}'),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        if (controller.tenantPage.total > controller.tenants.length) ...[
          const SizedBox(height: 12),
          Text(
            'Se muestran ${controller.tenants.length} de ${controller.tenantPage.total} tenants. La API limita esta consulta a 100 registros.',
          ),
        ],
      ],
    );
  }
}

class SuperadminTenantDetailPage extends StatefulWidget {
  const SuperadminTenantDetailPage({super.key, required this.tenantId});

  final String tenantId;

  @override
  State<SuperadminTenantDetailPage> createState() =>
      _SuperadminTenantDetailPageState();
}

class _SuperadminTenantDetailPageState
    extends State<SuperadminTenantDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<SuperadminController>().loadTenant(widget.tenantId);
  }

  @override
  void didUpdateWidget(covariant SuperadminTenantDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tenantId != widget.tenantId) {
      context.read<SuperadminController>().loadTenant(widget.tenantId);
    }
  }

  Future<void> _editTenant(PlatformTenant tenant) async {
    final payload = await showTenantFormDialog(context, tenant: tenant);
    if (payload == null || !mounted) return;
    final controller = context.read<SuperadminController>();
    final success = await controller.updateTenant(tenant.id, payload);
    if (!mounted) return;
    _showOperationResult(
      context,
      success: success,
      successMessage: 'Datos del tenant actualizados.',
      errorMessage: controller.errorMessage,
    );
  }

  Future<void> _changeTenantStatus(PlatformTenant tenant) async {
    final status = await showStatusDialog(
      context,
      title: 'Cambiar estado del tenant',
      currentStatus: tenant.status,
      statuses: const ['ACTIVE', 'PAUSED', 'SUSPENDED', 'BLOCKED'],
      labelFor: _tenantStatusLabel,
    );
    if (status == null || !mounted) return;
    final controller = context.read<SuperadminController>();
    final success = await controller.changeTenantStatus(tenant.id, status);
    if (!mounted) return;
    _showOperationResult(
      context,
      success: success,
      successMessage: 'Estado del tenant actualizado.',
      errorMessage: controller.errorMessage,
    );
  }

  Future<void> _toggleModule(
    PlatformTenant tenant,
    String moduleCode,
    bool isEnabled,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEnabled ? 'Activar módulo' : 'Desactivar módulo'),
        content: Text(
          isEnabled
              ? 'El módulo $moduleCode quedará contratado para este tenant.'
              : 'El módulo $moduleCode dejará de estar disponible para el tenant.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final current = {
      for (final module in tenant.modules) module.moduleCode: module.isEnabled,
      'CORE': true,
      moduleCode: isEnabled,
    };
    final modules = ['CORE', 'RETAIL', 'RESTAURANT']
        .map(
          (code) =>
              TenantModule(moduleCode: code, isEnabled: current[code] ?? false),
        )
        .toList();
    final controller = context.read<SuperadminController>();
    final success = await controller.updateModules(tenant.id, modules);
    if (!mounted) return;
    _showOperationResult(
      context,
      success: success,
      successMessage: 'Módulos actualizados.',
      errorMessage: controller.errorMessage,
    );
  }

  Future<void> _saveOwner(PlatformTenant tenant, {required bool create}) async {
    final controller = context.read<SuperadminController>();
    final payload = await showOwnerFormDialog(
      context,
      owner: create ? null : controller.ownersByTenant[tenant.id],
      creating: create,
    );
    if (payload == null || !mounted) return;
    final success = create
        ? await controller.createOwner({'tenantId': tenant.id, ...payload})
        : await controller.updateOwner(tenant.id, payload);
    if (!mounted) return;
    _showOperationResult(
      context,
      success: success,
      successMessage: create
          ? 'OWNER creado correctamente.'
          : 'OWNER actualizado correctamente.',
      errorMessage: controller.errorMessage,
    );
  }

  Future<void> _changeOwnerStatus(
    PlatformTenant tenant,
    OwnerAccount? owner,
  ) async {
    final status = await showStatusDialog(
      context,
      title: 'Cambiar estado del OWNER',
      currentStatus: owner?.status ?? 'ACTIVE',
      statuses: const ['ACTIVE', 'INACTIVE', 'SUSPENDED'],
      labelFor: _ownerStatusLabel,
    );
    if (status == null || !mounted) return;
    final controller = context.read<SuperadminController>();
    final success = await controller.changeOwnerStatus(tenant.id, status);
    if (!mounted) return;
    _showOperationResult(
      context,
      success: success,
      successMessage: 'Estado del OWNER actualizado.',
      errorMessage: controller.errorMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SuperadminController>();
    final tenant = controller.selectedTenant?.id == widget.tenantId
        ? controller.selectedTenant
        : controller.tenants
              .where((candidate) => candidate.id == widget.tenantId)
              .firstOrNull;
    if (controller.loading && tenant == null) {
      return const AppLoadingState(message: 'Cargando tenant…');
    }
    if (controller.errorMessage case final message? when tenant == null) {
      return AppErrorState(
        message: message,
        onRetry: () => controller.loadTenant(widget.tenantId),
      );
    }
    if (tenant == null) {
      return AppErrorState(
        message: 'No encontramos el tenant solicitado.',
        onRetry: () => context.go('/superadmin/tenants'),
      );
    }
    final owner = controller.ownersByTenant[tenant.id];
    final modules = {
      for (final module in tenant.modules) module.moduleCode: module.isEnabled,
    };

    return _SuperadminPageFrame(
      children: [
        PageHeader(
          title: tenant.name,
          subtitle: '${tenant.slug} · ${tenant.primaryEmail}',
          actions: [
            OutlinedButton.icon(
              onPressed: controller.saving ? null : () => _editTenant(tenant),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
            ),
            FilledButton.tonalIcon(
              onPressed: controller.saving
                  ? null
                  : () => _changeTenantStatus(tenant),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Cambiar estado'),
            ),
          ],
        ),
        if (controller.saving || controller.loading) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 250,
              child: MetricCard(
                label: 'Estado',
                value: _tenantStatusLabel(tenant.status),
                icon: Icons.verified_user_outlined,
                color: _tenantStatusColor(tenant.status),
              ),
            ),
            SizedBox(
              width: 250,
              child: MetricCard(
                label: 'Plan',
                value: tenant.planCode,
                icon: Icons.workspace_premium_outlined,
              ),
            ),
            SizedBox(
              width: 250,
              child: MetricCard(
                label: 'Sucursales',
                value: '${tenant.branches.length}',
                icon: Icons.store_outlined,
              ),
            ),
            SizedBox(
              width: 250,
              child: MetricCard(
                label: 'Módulos activos',
                value: '${tenant.enabledModuleCount}',
                icon: Icons.extension_outlined,
                color: AppColors.tenantAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 980
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Datos corporativos',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(label: 'ID', value: tenant.id),
                        _DetailRow(label: 'Slug', value: tenant.slug),
                        _DetailRow(label: 'Correo', value: tenant.primaryEmail),
                        _DetailRow(
                          label: 'Dirección',
                          value: tenant.address ?? 'No registrada',
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Módulos contratados',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('CORE'),
                          subtitle: const Text(
                            'Módulo base obligatorio del tenant.',
                          ),
                          value: true,
                          onChanged: null,
                        ),
                        for (final code in const ['RETAIL', 'RESTAURANT'])
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(code),
                            subtitle: Text(
                              modules[code] == true
                                  ? 'Activo en el backend'
                                  : 'Inactivo en el backend',
                            ),
                            value: modules[code] ?? false,
                            onChanged: controller.saving
                                ? null
                                : (value) => _toggleModule(tenant, code, value),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sucursales reportadas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              if (tenant.branches.isEmpty)
                const Text('Este tenant no tiene sucursales registradas.')
              else
                for (final branch in tenant.branches)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.store_outlined),
                    ),
                    title: Text(branch.name),
                    subtitle: Text(
                      '${branch.code} · ${branch.address ?? 'Sin dirección'}',
                    ),
                    trailing: AppBadge(
                      label: branch.status ?? 'Sin estado',
                      color: branch.status == 'ACTIVE'
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'OWNER del tenant',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: controller.saving
                            ? null
                            : () => _saveOwner(tenant, create: true),
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: const Text('Crear'),
                      ),
                      OutlinedButton.icon(
                        onPressed: controller.saving
                            ? null
                            : () => _saveOwner(tenant, create: false),
                        icon: const Icon(Icons.manage_accounts_outlined),
                        label: const Text('Actualizar'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: controller.saving
                            ? null
                            : () => _changeOwnerStatus(tenant, owner),
                        icon: const Icon(Icons.toggle_on_outlined),
                        label: const Text('Estado'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (owner == null)
                const Text(
                  'El backend de HU01 no expone un endpoint GET para consultar al OWNER. '
                  'Aquí solo se mostrarán datos reales devueltos después de crear, actualizar '
                  'o cambiar su estado durante esta sesión.',
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(owner.fullName),
                  subtitle: Text(owner.email),
                  trailing: AppBadge(
                    label: _ownerStatusLabel(owner.status),
                    color: owner.status == 'ACTIVE'
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class SuperadminModulePage extends StatelessWidget {
  const SuperadminModulePage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _SuperadminPageFrame(
    children: [
      PageHeader(title: title, subtitle: description),
      const SizedBox(height: 20),
      AppCard(
        child: Row(
          children: [
            CircleAvatar(radius: 28, child: Icon(icon)),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'HU01 no define operaciones backend para esta ruta. Se mantiene informativa y sin datos simulados.',
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _TenantStatus extends StatelessWidget {
  const _TenantStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) => AppBadge(
    label: _tenantStatusLabel(status),
    color: _tenantStatusColor(status),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        Expanded(child: SelectableText(value)),
      ],
    ),
  );
}

class _SuperadminPageFrame extends StatelessWidget {
  const _SuperadminPageFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    ),
  );
}

String _tenantStatusLabel(String status) => switch (status) {
  'ACTIVE' => 'Activo',
  'PAUSED' => 'Pausado',
  'SUSPENDED' => 'Suspendido',
  'BLOCKED' => 'Bloqueado',
  _ => status,
};

String _ownerStatusLabel(String status) => switch (status) {
  'ACTIVE' => 'Activo',
  'INACTIVE' => 'Inactivo',
  'SUSPENDED' => 'Suspendido',
  _ => status,
};

Color _tenantStatusColor(String status) => switch (status) {
  'ACTIVE' => AppColors.success,
  'SUSPENDED' || 'BLOCKED' => AppColors.destructive,
  _ => AppColors.warning,
};

void _showOperationResult(
  BuildContext context, {
  required bool success,
  required String successMessage,
  String? errorMessage,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          success
              ? successMessage
              : errorMessage ?? 'No fue posible completar la operación.',
        ),
        backgroundColor: success
            ? AppColors.success
            : Theme.of(context).colorScheme.error,
      ),
    );
}
