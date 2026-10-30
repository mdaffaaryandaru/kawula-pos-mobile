import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../discounts/domain/entities/discount_definition.dart';
import '../../../discounts/domain/repositories/discounts_repository.dart';
import '../../../products/domain/entities/catalog_product.dart';
import '../../../products/domain/repositories/catalog_repository.dart';
import '../../domain/entities/membership_program.dart';
import '../../domain/repositories/members_repository.dart';

sealed class MembershipProgramState {
  const MembershipProgramState();
}

final class MembershipProgramLoading extends MembershipProgramState {
  const MembershipProgramLoading();
}

final class MembershipProgramLoaded extends MembershipProgramState {
  const MembershipProgramLoaded({
    required this.program,
    required this.products,
    required this.discounts,
    this.errorMessage,
  });

  final MembershipProgram program;
  final List<CatalogProduct> products;
  final List<DiscountDefinition> discounts;
  final String? errorMessage;
}

final class MembershipProgramFailure extends MembershipProgramState {
  const MembershipProgramFailure(this.message);

  final String message;
}

class MembershipProgramCubit extends Cubit<MembershipProgramState> {
  MembershipProgramCubit(
    this._membersRepository,
    this._catalogRepository,
    this._discountsRepository,
  ) : super(const MembershipProgramLoading());

  final MembersRepository _membersRepository;
  final CatalogRepository _catalogRepository;
  final DiscountsRepository _discountsRepository;

  Future<void> load() async {
    emit(const MembershipProgramLoading());
    try {
      final program = await _membersRepository.getMembershipProgram();
      final products = await _catalogRepository.getProducts();
      final discounts = await _discountsRepository.getDiscounts();
      emit(
        MembershipProgramLoaded(
          program: program,
          products: products
              .where((product) => product.isActive)
              .toList(growable: false),
          discounts: discounts
              .where((discount) => discount.isActive)
              .toList(growable: false),
        ),
      );
    } catch (error) {
      emit(MembershipProgramFailure(_messageFor(error)));
    }
  }

  Future<bool> save({
    required int targetVisits,
    required String rewardType,
    required String? rewardId,
    required bool isActive,
  }) async {
    final currentState = state;
    if (currentState is! MembershipProgramLoaded) return false;
    try {
      final program = await _membersRepository.saveMembershipProgram(
        targetVisits: targetVisits,
        rewardType: rewardType,
        rewardId: rewardId,
        isActive: isActive,
      );
      emit(
        MembershipProgramLoaded(
          program: program,
          products: currentState.products,
          discounts: currentState.discounts,
        ),
      );
      return true;
    } catch (error) {
      emit(
        MembershipProgramLoaded(
          program: currentState.program,
          products: currentState.products,
          discounts: currentState.discounts,
          errorMessage: _messageFor(error),
        ),
      );
      return false;
    }
  }

  String _messageFor(Object error) {
    if (error is FormatException) return error.message;
    return error.toString();
  }
}
