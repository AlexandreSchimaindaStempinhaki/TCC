import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/models/user_entity.dart';
import 'package:http/http.dart' as http;
import 'i_user_firebase_service.dart';

final class UserRemoteServiceImpl implements IUserRemoteService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String cloudName = 'db37erprw';
  final String uploadPreset = 'tcc_pics';

  UserRemoteServiceImpl({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String get _currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Nenhum usuário autenticado no Firebase Auth.');
    }
    return uid;
  }

  @override
  Future<void> saveUserData(UserModel user) async {
    final uid = user.uid.isNotEmpty ? user.uid : _currentUid;
    await _firestore
        .collection('users')
        .doc(uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  @override
  Future<UserModel?> getUserData() async {
    final uid = _currentUid;
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists || doc.data() == null) return null;

    return UserModel.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<String> uploadProfileImage(File imageFile) async {
    final uid = _currentUid;

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/db37erprw/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] =
          'tcc_pics'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonMap = jsonDecode(responseData);
      final String secureUrl = jsonMap['secure_url'];

      await _firestore.collection('users').doc(uid).update({
        'photoUrl': secureUrl,
      });

      return secureUrl;
    } else {
      throw Exception(
        'Falha ao fazer upload da imagem. Status: ${response.statusCode}',
      );
    }
  }

  @override
  Future<void> deleteUserAccountData() async {
    final uid = _currentUid;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw Exception('Nenhum usuário autenticado para excluir.');
    }

    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      throw Exception('Erro ao excluir dados do banco: $e');
    }

    // O BLOCO DO STORAGE FOI REMOVIDO DAQUI

    try {
      await currentUser.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'Por segurança, você precisa sair do aplicativo, fazer login novamente e tentar excluir a conta.',
        );
      }
      throw Exception('Erro na exclusão do Auth: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao excluir conta: $e');
    }
  }
}
