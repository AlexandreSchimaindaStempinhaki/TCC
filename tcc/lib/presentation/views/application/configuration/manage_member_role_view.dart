import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/models/company_entity.dart';
import '../../../../domain/models/user_entity.dart';
import '../../../widgets/animated_three_dots.dart';

class ManageMemberRoleView extends StatefulWidget {
  final CompanyModel? company;
  final String memberId;
  final UserModel userModel;
  final String currentRoleCategory;
  final bool isCurrentUserOwner;
  final bool isCurrentUserManager;

  const ManageMemberRoleView({
    super.key,
    required this.company,
    required this.memberId,
    required this.userModel,
    required this.currentRoleCategory,
    required this.isCurrentUserOwner,
    required this.isCurrentUserManager,
  });

  @override
  State<ManageMemberRoleView> createState() => _ManageMemberRoleViewState();
}

class _ManageMemberRoleViewState extends State<ManageMemberRoleView> {
  late String _selectedRole;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.currentRoleCategory;
  }

  String _cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _roleLabel(String category) {
    switch (category) {
      case 'owner':
        return 'Proprietário (CEO)';
      case 'manager':
        return 'Gerente';
      case 'driver':
        return 'Motorista';
      case 'passenger':
      default:
        return 'Passageiro';
    }
  }

  List _availableRoleOptions() {
    final options = [];

    if (widget.isCurrentUserOwner) {
      options.add({
        'category': 'manager',
        'title': 'Gerente',
        'description':
            'Pode criar e editar rotas, aprovar solicitações de vínculo e nomear ou desnomear motoristas.',
        'icon': Icons.manage_accounts_rounded,
        'accentColor': const Color(0xFF7C3AED),
      });
    }

    if (widget.isCurrentUserManager) {
      options.add({
        'category': 'driver',
        'title': 'Motorista',
        'description':
            'Responsável por conduzir as rotas da empresa e visualizar a lista de passageiros vinculados.',
        'icon': Icons.directions_bus_rounded,
        'accentColor': const Color(0xFFD97706),
      });
    }

    options.add({
      'category': 'passenger',
      'title': 'Passageiro',
      'description':
          'Usuário vinculado apenas às linhas de transporte, sem permissões administrativas na empresa.',
      'icon': Icons.people_alt_rounded,
      'accentColor': const Color(0xFF15803D),
    });

    return options;
  }

  Future<void> _confirmAndSaveRole() async {
    if (_selectedRole == widget.currentRoleCategory) {
      context.pop(false);
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final targetLabel = _roleLabel(_selectedRole);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.manage_accounts_rounded,
              color: colorScheme.primary,
              size: 26,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Confirmar Novo Cargo?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Deseja alterar o cargo de "${widget.userModel.name}" para "$targetLabel"?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Confirmar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _saveRoleToFirestore();
  }

  Future<void> _saveRoleToFirestore() async {
    final company = widget.company;
    final rawCnpj = _cleanDigits(company?.cnpj ?? '');
    if (rawCnpj.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final membersRef = firestore.collection('company_members');
      final memberId = widget.memberId.trim();
      final cleanMemberId = _cleanDigits(memberId);

      final existingSnap = await membersRef
          .where('companyCnpj', isEqualTo: rawCnpj)
          .get();

      DocumentReference? matchedDocRef;
      for (final doc in existingSnap.docs) {
        final data = doc.data();
        final docUserId =
            (data['userId'] ?? data['cpf'] ?? data['email'] ?? '')
                .toString()
                .trim();
        final docCleanId = _cleanDigits(docUserId);

        if (docUserId == memberId ||
            (cleanMemberId.isNotEmpty && docCleanId == cleanMemberId)) {
          matchedDocRef = doc.reference;
          break;
        }
      }

      if (matchedDocRef != null) {
        await matchedDocRef.update({
          'role': _selectedRole,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final docId =
            '${rawCnpj}_${cleanMemberId.isNotEmpty ? cleanMemberId : memberId}';
        await membersRef.doc(docId).set({
          'companyCnpj': rawCnpj,
          'userId': memberId,
          'cpf': widget.userModel.cpf ?? cleanMemberId,
          'email': widget.userModel.email,
          'role': _selectedRole,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (company != null) {
        final updatedMemberIds = List<String>.from(company.memberIds);
        if (_selectedRole == 'manager' || _selectedRole == 'driver') {
          if (!updatedMemberIds.contains(memberId)) {
            updatedMemberIds.add(memberId);
          }
        } else {
          updatedMemberIds.removeWhere(
            (id) =>
                id.trim() == memberId ||
                (cleanMemberId.isNotEmpty && _cleanDigits(id) == cleanMemberId),
          );
        }

        try {
          await firestore.collection('companies').doc(rawCnpj).update({
            'memberIds': updatedMemberIds,
          });
        } catch (_) {}
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Cargo atualizado com sucesso!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
          ),
        );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao atualizar cargo: $e',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFCBD5E1);
    final Color surfaceColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);

    final roleOptions = _availableRoleOptions();
    final photoUrl = widget.userModel.photoUrl ?? '';
    final hasChanged = _selectedRole != widget.currentRoleCategory;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
          onPressed: () => context.pop(false),
          tooltip: 'Voltar',
        ),
        title: Column(
          children: [
            Text(
              'Alterar Cargo',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (widget.company != null &&
                widget.company!.name.trim().isNotEmpty)
              Text(
                widget.company!.name,
                style: TextStyle(
                  color: colorScheme.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor, width: 1.6),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: surfaceColor,
                  backgroundImage: photoUrl.trim().isNotEmpty
                      ? NetworkImage(photoUrl.trim())
                      : null,
                  child: photoUrl.trim().isEmpty
                      ? Icon(
                          Icons.person_rounded,
                          color: colorScheme.onSurface,
                          size: 28,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userModel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cargo atual: ${_roleLabel(widget.currentRoleCategory)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Selecione o novo cargo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          ...roleOptions.map((option) {
            final category = option['category'] as String;
            final title = option['title'] as String;
            final description = option['description'] as String;
            final icon = option['icon'] as IconData;
            final accentColor = option['accentColor'] as Color;
            final isSelected = _selectedRole == category;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRole = category;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : borderColor,
                    width: isSelected ? 2.2 : 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.secondary,
                                size: 22,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.secondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: borderColor, width: 1.2),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_isSaving || !hasChanged) ? null : _confirmAndSaveRole,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                disabledBackgroundColor: surfaceColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? AnimatedThreeDots(color: colorScheme.onSurface)
                  : Text(
                      hasChanged ? 'Salvar Novo Cargo' : 'Selecione um Cargo Diferente',
                      style: TextStyle(
                        color: hasChanged ? Colors.white : colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}