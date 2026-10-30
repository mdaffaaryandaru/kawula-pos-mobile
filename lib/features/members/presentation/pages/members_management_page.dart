import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../framework/widgets/master_data_feedback.dart';
import '../../../../framework/widgets/master_data_header.dart';
import '../../../../framework/widgets/master_data_row_actions.dart';
import '../../../../framework/widgets/master_data_search_panel.dart';
import '../../../../framework/widgets/master_data_status_badge.dart';
import '../../../../framework/widgets/responsive_data_table.dart';
import '../../domain/entities/member.dart';
import '../../domain/entities/membership_program.dart';
import '../../domain/repositories/members_repository.dart';
import '../bloc/members_cubit.dart';
import '../widgets/member_dialog.dart';

class MembersManagementPage extends StatelessWidget {
  const MembersManagementPage({super.key, required this.repository});

  final MembersRepository repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => MembersCubit(repository)..load(),
    child: const _MembersView(),
  );
}

class _MembersView extends StatefulWidget {
  const _MembersView();

  @override
  State<_MembersView> createState() => _MembersViewState();
}

class _MembersViewState extends State<_MembersView> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<MembersCubit, MembersState>(
        listener: (context, state) {
          final message = switch (state) {
            MembersLoaded(errorMessage: final error?) => error,
            MembersFailure(:final message) => message,
            _ => null,
          };
          if (message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Members'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => context.read<MembersCubit>().load(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: SafeArea(
            child: BlocBuilder<MembersCubit, MembersState>(
              builder: (context, state) => switch (state) {
                MembersLoading() => const MasterDataLoadingState(),
                MembersFailure(:final message) => MasterDataErrorState(
                  title: 'Daftar member belum dapat dimuat.',
                  message: message,
                  onRetry: context.read<MembersCubit>().load,
                ),
                MembersLoaded(:final members, :final program) => _buildLoaded(
                  context,
                  members,
                  program,
                ),
              },
            ),
          ),
        ),
      );

  Widget _buildLoaded(
    BuildContext context,
    List<Member> members,
    MembershipProgram program,
  ) {
    final visible = members
        .where(
          (member) => '${member.name} ${member.phoneNumber} ${member.email}'
              .toLowerCase()
              .contains(_query),
        )
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: context.read<MembersCubit>().load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _header(context),
            const SizedBox(height: 20),
            _searchPanel(),
            const SizedBox(height: 20),
            if (members.isEmpty)
              MasterDataEmptyState(
                icon: Icons.people_outline,
                title: 'Belum ada member.',
                message: 'Daftarkan member untuk menyimpan data pelanggan.',
                onAction: () => _editMember(context),
                actionLabel: 'Tambah Member',
              )
            else if (visible.isEmpty)
              const MasterDataEmptyState(
                icon: Icons.search_off,
                title: 'Member tidak ditemukan.',
                message: 'Coba kata pencarian lainnya.',
              )
            else
              _membersTable(context, visible, program, constraints.maxWidth),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => MasterDataHeader(
    eyebrow: 'ADMINISTRASI',
    title: 'Members',
    description: 'Kelola data pelanggan member.',
    addLabel: 'Tambah Member',
    onRefresh: () => context.read<MembersCubit>().load(),
    onAdd: () => _editMember(context),
  );

  Widget _searchPanel() => MasterDataSearchPanel(
    controller: _searchController,
    onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
    query: _query,
    hintText: 'Cari nama, email, atau telepon...',
  );

  Widget _membersTable(
    BuildContext context,
    List<Member> members,
    MembershipProgram program,
    double availableWidth,
  ) => ResponsiveDataTable(
    minWidth: availableWidth - 40,
    columns: const [
      DataColumn(label: Text('NAMA')),
      DataColumn(label: Text('TELEPON')),
      DataColumn(label: Text('EMAIL')),
      DataColumn(label: Text('PROGRAM')),
      DataColumn(label: Text('POIN')),
      DataColumn(label: Text('STATUS')),
      DataColumn(label: Text('AKSI')),
    ],
    rows: members
        .map((member) => _memberRow(context, member, program))
        .toList(growable: false),
  );

  DataRow _memberRow(
    BuildContext context,
    Member member,
    MembershipProgram program,
  ) => DataRow(
    cells: [
      DataCell(SizedBox(width: 170, child: Text(member.name))),
      DataCell(SizedBox(width: 150, child: Text(member.phoneNumber))),
      DataCell(
        SizedBox(
          width: 190,
          child: Text(
            member.email.isEmpty ? '-' : member.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      DataCell(
        SizedBox(
          width: 200,
          child: Text(
            program.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      DataCell(
        Chip(
          label: Text('${member.currentStamps}'),
          visualDensity: VisualDensity.compact,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          side: BorderSide.none,
        ),
      ),
      DataCell(MasterDataStatusBadge(isActive: member.isActive)),
      DataCell(
        MasterDataRowActions(
          onEdit: () => _editMember(context, member),
          onDelete: () => _deleteMember(context, member),
        ),
      ),
    ],
  );

  Future<void> _editMember(BuildContext context, [Member? member]) async {
    final draft = await showDialog<MemberDraft>(
      context: context,
      builder: (_) => MemberDialog(member: member),
    );
    if (draft == null || !context.mounted) return;
    final cubit = context.read<MembersCubit>();
    final success = member == null
        ? await cubit.createMember(
            name: draft.name,
            phoneNumber: draft.phoneNumber,
            email: draft.email,
          )
        : await cubit.updateMember(
            memberId: member.id,
            name: draft.name,
            phoneNumber: draft.phoneNumber,
            email: draft.email,
            isActive: draft.isActive,
          );
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            member == null
                ? 'Member berhasil ditambahkan.'
                : 'Member berhasil diperbarui.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteMember(BuildContext context, Member member) async {
    final confirmed = await MasterDataDeleteConfirmation.show(
      context,
      title: 'Hapus member?',
      message: 'Member "${member.name}" akan dihapus permanen.',
    );
    if (confirmed != true || !context.mounted) return;
    final success = await context.read<MembersCubit>().deleteMember(member.id);
    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Member berhasil dihapus.')));
    }
  }
}
