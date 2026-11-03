// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/discounts/domain/repositories/discounts_repository.dart';
import 'package:kawula_pos/features/membership_programs/domain/repositories/membership_programs_repository.dart';
import 'package:kawula_pos/features/membership_programs/presentation/bloc/membership_program_cubit.dart';
import 'package:kawula_pos/features/membership_programs/presentation/widgets/membership_program_form.dart';
import 'package:kawula_pos/features/products/domain/repositories/catalog_repository.dart';
import 'package:kawula_pos/framework/widgets/master_data_feedback.dart';

class MembershipProgramPage extends StatelessWidget {
  const MembershipProgramPage({
    super.key,
    required this.membershipProgramsRepository,
    required this.catalogRepository,
    required this.discountsRepository,
  });

  final MembershipProgramsRepository membershipProgramsRepository;
  final CatalogRepository catalogRepository;
  final DiscountsRepository discountsRepository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => MembershipProgramCubit(
      membershipProgramsRepository,
      catalogRepository,
      discountsRepository,
    )..load(),
    child: const _MembershipProgramView(),
  );
}

class _MembershipProgramView extends StatelessWidget {
  const _MembershipProgramView();

  @override
  Widget build(BuildContext context) =>
      BlocListener<MembershipProgramCubit, MembershipProgramState>(
        listener: (context, state) {
          final message = switch (state) {
            MembershipProgramLoaded(errorMessage: final error?) => error,
            MembershipProgramFailure(:final message) => message,
            _ => null,
          };
          if (message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Program Membership')),
          body: SafeArea(
            child: BlocBuilder<MembershipProgramCubit, MembershipProgramState>(
              builder: (context, state) => switch (state) {
                MembershipProgramLoading() => const MasterDataLoadingState(),
                MembershipProgramFailure(:final message) =>
                  MasterDataErrorState(
                    title: 'Program membership belum dapat dimuat.',
                    message: message,
                    onRetry: context.read<MembershipProgramCubit>().load,
                  ),
                MembershipProgramLoaded(
                  :final program,
                  :final products,
                  :final discounts,
                ) =>
                  MembershipProgramForm(
                    program: program,
                    products: products,
                    discounts: discounts,
                  ),
              },
            ),
          ),
        ),
      );
}
