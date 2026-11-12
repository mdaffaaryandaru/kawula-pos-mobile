import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/transactions/data/repositories/offline_transaction_queue_repository_impl.dart';
import 'package:kawula_pos/features/transactions/data/services/admin_offline_resolution_service.dart';
import 'package:kawula_pos/features/transactions/data/models/checkout_models.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/offline_transaction_queue_repository.dart';
import 'package:kawula_pos/framework/core/offline/database/app_database.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/offline_transactions_dao.dart';

void main() {
  late AppDatabase database;
  late OfflineTransactionsDao dao;
  late OfflineTransactionQueueRepository queueRepository;
  late Future<AuthUser?> Function() currentVerifier;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    dao = database.offlineTransactionsDao;
    queueRepository = OfflineTransactionQueueRepositoryImpl(dao);
  });

  tearDown(() async {
    await database.close();
  });

  Future<OfflineTransaction> saveTransaction({
    String outletId = 'outlet-1',
    OfflineTransactionStatus status =
        OfflineTransactionStatus.needsReconciliation,
    DateTime? createdAtLocal,
  }) async {
    return dao.saveOfflineTransaction(
      ownerUserId: 'cashier-1',
      outletId: outletId,
      shiftId: 'shift-1',
      transactionType: 'sale',
      payload: {
        'total_amount': 12000,
        'payment_method': 'CASH',
        'items': [
          {
            'product_id': 'product-1',
            'quantity': 1,
            'selected_variants': [
              {'group_name': 'Ukuran', 'option_name': 'Regular'},
            ],
          },
        ],
      },
      receiptSnapshot: {'cashier_id': 'cashier-1', 'total_amount': 12000},
      status: status,
      lastError: status == OfflineTransactionStatus.failed
          ? 'Business rejection'
          : null,
      createdAtLocal: createdAtLocal ?? DateTime.utc(2026, 11, 10, 10),
    );
  }

  AuthUser admin({bool offline = false, String role = 'Admin'}) => AuthUser(
    id: 'admin-1',
    name: 'Admin',
    email: 'admin@example.invalid',
    role: role,
    hasPin: true,
    isOfflineSession: offline,
  );

  TransactionRecord remote({
    String id = 'remote-1',
    String outletId = 'outlet-1',
    String cashierId = 'cashier-1',
    String productId = 'product-1',
    num total = 12000,
    String paymentMethod = 'CASH',
    DateTime? createdAt,
  }) {
    return TransactionRecord(
      id: id,
      status: 'completed',
      totalAmount: total,
      paymentMethod: paymentMethod,
      paidAmount: total,
      changeAmount: 0,
      createdAt: createdAt ?? DateTime.utc(2026, 11, 10, 10, 1),
      outletId: outletId,
      cashierId: cashierId,
      items: [
        TransactionRecordItem(
          productId: productId,
          productName: 'Kopi',
          quantity: 1,
          price: 12000,
          selectedVariants: const [
            CheckoutResultVariant(groupName: 'Ukuran', optionName: 'Regular'),
          ],
        ),
      ],
    );
  }

  AdminOfflineResolutionService service({
    required _CheckoutRepositoryFake repository,
    required Future<AuthUser?> Function() verify,
  }) {
    currentVerifier = verify;
    return AdminOfflineResolutionService(
      queueRepository: queueRepository,
      checkoutRepository: repository,
    );
  }

  test(
    'candidate matching uses transaction details and leaves amount for review',
    () async {
      final local = await saveTransaction();
      final repository = _CheckoutRepositoryFake([
        remote(id: 'matching'),
        remote(id: 'rounding-difference', total: 11999),
        remote(id: 'wrong-outlet', outletId: 'outlet-2'),
        remote(id: 'wrong-owner', cashierId: 'cashier-2'),
        remote(id: 'same-total-only', productId: 'product-2'),
      ]);

      final candidates =
          await service(
            repository: repository,
            verify: () async => admin(),
          ).findCandidates(
            localId: local.localId,
            activeOutletId: 'outlet-1',
            verifyAdminSession: currentVerifier,
          );

      expect(candidates.map((candidate) => candidate.id), [
        'matching',
        'rounding-difference',
      ]);
      expect(
        (await dao.getTransactionByLocalId(local.localId))!.status,
        'needs_reconciliation',
      );
    },
  );

  test('candidate time window prioritizes nearby candidates but retains older ones', () async {
    final local = await saveTransaction(
      createdAtLocal: DateTime.parse('2026-11-10T23:59:00-05:00'),
    );
    final repository = _CheckoutRepositoryFake([
      remote(
        id: 'outside-window',
        createdAt: DateTime.parse('2026-11-12T05:00:01Z'),
      ),
      remote(
        id: 'near-midnight',
        total: 11999,
        createdAt: DateTime.parse('2026-11-11T00:01:00-05:00'),
      ),
    ]);

    final candidates =
        await service(
          repository: repository,
          verify: () async => admin(),
        ).findCandidates(
          localId: local.localId,
          activeOutletId: 'outlet-1',
          verifyAdminSession: currentVerifier,
        );

    expect(candidates.map((candidate) => candidate.id), [
      'near-midnight',
      'outside-window',
    ]);
    expect(
      (await dao.getTransactionByLocalId(local.localId))!.status,
      'needs_reconciliation',
    );
  });

  test(
    'transaction history parser retains server IDs needed for safe matching',
    () {
      final transaction = TransactionRecordModel.fromJson({
        '_id': 'remote-1',
        'status': 'completed',
        'total_amount': 12000,
        'payment_method': 'CASH',
        'paid_amount': 12000,
        'change_amount': 0,
        'created_at': '2026-11-10T10:01:00Z',
        'outlet_id': {'_id': 'outlet-1', 'name': 'Outlet A'},
        'created_by': {'_id': 'cashier-1', 'name': 'Kasir A'},
        'items': [
          {
            'product_id': {'_id': 'product-1', 'name': 'Kopi'},
            'quantity': 1,
            'price': 12000,
            'selected_variants': [
              {'group_name': 'Ukuran', 'option_name': 'Regular'},
            ],
          },
        ],
      });

      expect(transaction.outletId, 'outlet-1');
      expect(transaction.cashierId, 'cashier-1');
      expect(transaction.items.single.productId, 'product-1');
    },
  );

  test(
    'multiple server candidates are returned without choosing automatically',
    () async {
      final local = await saveTransaction();
      final repository = _CheckoutRepositoryFake([
        remote(id: 'remote-1'),
        remote(id: 'remote-2'),
      ]);

      final candidates =
          await service(
            repository: repository,
            verify: () async => admin(),
          ).findCandidates(
            localId: local.localId,
            activeOutletId: 'outlet-1',
            verifyAdminSession: currentVerifier,
          );

      expect(candidates.map((candidate) => candidate.id), [
        'remote-1',
        'remote-2',
      ]);
      expect(
        (await dao.getTransactionByLocalId(local.localId))!.status,
        'needs_reconciliation',
      );
    },
  );

  test('confirmed match records real server ID and admin audit', () async {
    final local = await saveTransaction();
    final repository = _CheckoutRepositoryFake([remote(id: 'server-real-id')]);
    final resolutionService = service(
      repository: repository,
      verify: () async => admin(),
    );

    await resolutionService.matchExistingRemote(
      localId: local.localId,
      activeOutletId: 'outlet-1',
      remoteTransactionId: 'server-real-id',
      reason: 'Reviewed receipt and server transaction details.',
      verifyAdminSession: currentVerifier,
    );

    final updated = await dao.getTransactionByLocalId(local.localId);
    final audit = await dao.getResolutionAudit(local.localId);
    expect(updated!.status, 'resolved_manually');
    expect(updated.remoteTransactionId, 'server-real-id');
    expect(updated.syncedAt, isNull);
    expect(updated.ownerUserId, 'cashier-1');
    expect(audit.single.resolutionType, 'matched_existing_remote');
    expect(audit.single.resolvingAdminUserId, 'admin-1');
    expect(audit.single.resolvingAdminRole, 'Admin');
  });

  test(
    'remote ID already used by another local transaction is rejected',
    () async {
      final existingOwner = await saveTransaction(
        status: OfflineTransactionStatus.pendingSync,
      );
      await dao.updateTransactionStatus(
        localId: existingOwner.localId,
        status: OfflineTransactionStatus.synced,
        remoteTransactionId: 'already-used',
      );
      final local = await saveTransaction();
      await dao.updateTransactionStatus(
        localId: local.localId,
        status: OfflineTransactionStatus.needsReconciliation,
        lastError: 'Preserve this error.',
      );
      final before = await dao.getTransactionByLocalId(local.localId);
      final repository = _CheckoutRepositoryFake([remote(id: 'already-used')]);

      await expectLater(
        service(
          repository: repository,
          verify: () async => admin(),
        ).matchExistingRemote(
          localId: local.localId,
          activeOutletId: 'outlet-1',
          remoteTransactionId: 'already-used',
          reason: 'Reviewed.',
          verifyAdminSession: currentVerifier,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('sudah terhubung'),
          ),
        ),
      );

      final after = await dao.getTransactionByLocalId(local.localId);
      expect(after!.status, before!.status);
      expect(after.remoteTransactionId, before.remoteTransactionId);
      expect(after.payloadJson, before.payloadJson);
      expect(after.receiptSnapshotJson, before.receiptSnapshotJson);
      expect(after.lastError, before.lastError);
      expect(await dao.getResolutionAudit(local.localId), isEmpty);
      expect(
        (await dao.getTransactionByLocalId(existingOwner.localId))!
            .remoteTransactionId,
        'already-used',
      );
    },
  );

  test('concurrent resolutions cannot share a remote ID', () async {
    final first = await saveTransaction();
    final second = await saveTransaction();

    Future<bool> attempt(String localId) async {
      try {
        return await queueRepository.resolveManually(
          localId: localId,
          outletId: 'outlet-1',
          adminUserId: 'admin-1',
          adminRole: 'Admin',
          resolutionType: 'matched_existing_remote',
          remoteTransactionId: 'shared-concurrent-id',
          resolvedAt: DateTime.utc(2026, 11, 10, 11),
          reason: 'Manually verified.',
        );
      } on StateError {
        return false;
      }
    }

    final results = await Future.wait([
      attempt(first.localId),
      attempt(second.localId),
    ]);
    final firstAfter = await dao.getTransactionByLocalId(first.localId);
    final secondAfter = await dao.getTransactionByLocalId(second.localId);
    final audits = [
      ...await dao.getResolutionAudit(first.localId),
      ...await dao.getResolutionAudit(second.localId),
    ];

    expect(results.where((result) => result).length, 1);
    expect(
      [
        firstAfter!.remoteTransactionId,
        secondAfter!.remoteTransactionId,
      ].where((id) => id == 'shared-concurrent-id').length,
      1,
    );
    expect(audits, hasLength(1));
  });

  test(
    'resolving the same local transaction and remote ID is idempotent',
    () async {
      final local = await saveTransaction();
      final resolutionService = service(
        repository: _CheckoutRepositoryFake([
          remote(id: 'same-local-remote-id'),
        ]),
        verify: () async => admin(),
      );

      Future<void> resolve() => resolutionService.matchExistingRemote(
        localId: local.localId,
        activeOutletId: 'outlet-1',
        remoteTransactionId: 'same-local-remote-id',
        reason: 'Manually verified again.',
        verifyAdminSession: currentVerifier,
      );

      await resolve();
      await resolve();
      final updated = await dao.getTransactionByLocalId(local.localId);

      expect(updated!.status, 'resolved_manually');
      expect(updated.remoteTransactionId, 'same-local-remote-id');
      expect(updated.payloadJson, local.payloadJson);
      expect(updated.receiptSnapshotJson, local.receiptSnapshotJson);
      expect(await dao.getResolutionAudit(local.localId), hasLength(1));
    },
  );

  test('no candidate leaves unknown outcome unresolved', () async {
    final local = await saveTransaction();
    final repository = _CheckoutRepositoryFake([]);

    final candidates =
        await service(
          repository: repository,
          verify: () async => admin(),
        ).findCandidates(
          localId: local.localId,
          activeOutletId: 'outlet-1',
          verifyAdminSession: currentVerifier,
        );

    expect(candidates, isEmpty);
    expect(
      (await dao.getTransactionByLocalId(local.localId))!.status,
      'needs_reconciliation',
    );
    expect(await dao.getResolutionAudit(local.localId), isEmpty);
  });

  test('offline or non-Admin sessions cannot search or resolve', () async {
    final local = await saveTransaction();
    final repository = _CheckoutRepositoryFake([remote()]);

    for (final session in [admin(offline: true), admin(role: 'Kasir')]) {
      final resolutionService = service(
        repository: repository,
        verify: () async => session,
      );
      await expectLater(
        resolutionService.findCandidates(
          localId: local.localId,
          activeOutletId: 'outlet-1',
          verifyAdminSession: currentVerifier,
        ),
        throwsStateError,
      );
    }

    await expectLater(
      service(
        repository: repository,
        verify: () async => null,
      ).matchExistingRemote(
        localId: local.localId,
        activeOutletId: 'outlet-1',
        remoteTransactionId: 'remote-1',
        reason: 'Not verified.',
        verifyAdminSession: currentVerifier,
      ),
      throwsStateError,
    );
    expect(repository.requestCount, 0);
    expect(
      (await dao.getTransactionByLocalId(local.localId))!.status,
      'needs_reconciliation',
    );
  });

  test(
    'service does not read or resolve a transaction outside active outlet',
    () async {
      final local = await saveTransaction(outletId: 'outlet-2');
      final repository = _CheckoutRepositoryFake([
        remote(outletId: 'outlet-2'),
      ]);
      final resolutionService = service(
        repository: repository,
        verify: () async => admin(),
      );

      await expectLater(
        resolutionService.findCandidates(
          localId: local.localId,
          activeOutletId: 'outlet-1',
          verifyAdminSession: currentVerifier,
        ),
        throwsStateError,
      );
      expect(repository.requestCount, 0);
    },
  );

  test(
    'only definite failed transactions can be handled outside server',
    () async {
      final local = await saveTransaction(
        status: OfflineTransactionStatus.needsReconciliation,
      );
      final repository = _CheckoutRepositoryFake([]);

      await expectLater(
        service(
          repository: repository,
          verify: () async => admin(),
        ).handleFailedOutsideServer(
          localId: local.localId,
          activeOutletId: 'outlet-1',
          reason: 'Handled manually.',
          verifyAdminSession: currentVerifier,
        ),
        throwsStateError,
      );
      expect(
        (await dao.getTransactionByLocalId(local.localId))!.status,
        'needs_reconciliation',
      );
    },
  );
}

class _CheckoutRepositoryFake extends Fake implements CheckoutRepository {
  _CheckoutRepositoryFake(this.transactions);

  final List<TransactionRecord> transactions;
  int requestCount = 0;

  @override
  Future<List<TransactionRecord>> getTransactions() async {
    requestCount++;
    return transactions;
  }
}
