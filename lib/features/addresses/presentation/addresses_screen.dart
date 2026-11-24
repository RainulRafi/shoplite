import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/data_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_message.dart';
import '../../products/presentation/widgets/product_skeleton_tile.dart';
import '../domain/address.dart';
import '../domain/address_validators.dart';
import 'address_form_screen.dart';
import 'address_provider.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  Future<void> _openForm(BuildContext context, {Address? editing}) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddressFormScreen(editing: editing),
      ),
    );
    if (saved == true) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Address saved.')));
    }
  }

  Future<void> _setDefault(BuildContext context, Address address) async {
    final provider = context.read<AddressProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.setDefault(address.id!);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Default address updated.'
                : 'Could not update the default address.',
          ),
        ),
      );
  }

  Future<void> _confirmDelete(BuildContext context, Address address) async {
    final provider = context.read<AddressProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            final c = dialogContext.colors;
            return AlertDialog(
              backgroundColor: c.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: c.border),
              ),
              title: Text(
                'Delete this address?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
              content: Text(
                address.singleLine,
                style: TextStyle(fontSize: 14, height: 1.4, color: c.muted),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: c.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      color: c.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!confirmed) return;

    final ok = await provider.delete(address.id!);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Address deleted.' : 'Could not delete the address.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final provider = context.watch<AddressProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.ink),
        centerTitle: false,
        title: Text(
          'Addresses',
          style: TextStyle(
            color: c.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: switch (provider.status) {
        DataStatus.loading => Semantics(
          label: 'Loading your addresses',
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            children: const [ProductSkeletonTile(), ProductSkeletonTile()],
          ),
        ),
        DataStatus.error => StateMessage(
          title: 'Could not load your addresses',
          body: 'Something went wrong reading them from this phone.',
          titleColor: c.danger,
          action: FilledButton(
            onPressed: provider.retry,
            style: FilledButton.styleFrom(
              backgroundColor: c.accent,
              foregroundColor: c.onAccent,
              minimumSize: const Size(160, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Try again'),
          ),
        ),
        DataStatus.ready =>
          provider.addresses.isEmpty
              ? const StateMessage(
                  title: 'No saved addresses',
                  body:
                      'Add an address now and checkout will be quicker later.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: provider.addresses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final address = provider.addresses[index];
                    return _AddressCard(
                      address: address,
                      onEdit: () => _openForm(context, editing: address),
                      onSetDefault: () => _setDefault(context, address),
                      onDelete: () => _confirmDelete(context, address),
                    );
                  },
                ),
      },
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!provider.canAddMore) ...[
                Text(
                  'You can save up to ${AddressValidators.maxAddresses} addresses. '
                  'Delete one to add another.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: c.muted),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton(
                onPressed:
                    provider.status == DataStatus.ready && provider.canAddMore
                    ? () => _openForm(context)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: c.onAccent,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                child: const Text('Add new address'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    ButtonStyle action(Color color) => TextButton.styleFrom(
      foregroundColor: color,
      minimumSize: const Size(64, 48),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Text(
                  address.label.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.ink,
                  ),
                ),
                const Spacer(),
                if (address.isDefault)
                  Text(
                    'Default',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.accentFg,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(address.fullName, style: TextStyle(fontSize: 14, color: c.ink)),
          const SizedBox(height: 2),
          Text(address.phone, style: TextStyle(fontSize: 14, color: c.muted)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              address.singleLine,
              style: TextStyle(fontSize: 14, height: 1.4, color: c.muted),
            ),
          ),
          if (address.note != null && address.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'Note: ${address.note}',
                style: TextStyle(fontSize: 13, height: 1.4, color: c.faint),
              ),
            ),
          ],
          const SizedBox(height: 4),

          Wrap(
            children: [
              TextButton(
                onPressed: onEdit,
                style: action(c.accentFg),
                child: const Text('Edit'),
              ),
              if (!address.isDefault)
                TextButton(
                  onPressed: onSetDefault,
                  style: action(c.accentFg),
                  child: const Text('Make default'),
                ),
              TextButton(
                onPressed: onDelete,
                style: action(c.danger),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
