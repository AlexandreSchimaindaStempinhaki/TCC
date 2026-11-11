import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../domain/models/user_entity.dart';
import 'i_user_remote_service.dart';

final class UserRemoteServiceImpl implements IUserRemoteService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  UserRemoteServiceImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
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
    final ref = _storage.ref().child('profile_images').child('$uid.jpg');

    final uploadTask = await ref.putFile(imageFile);
    return await uploadTask.ref.getDownloadURL();
  }

  @override
  Future<void> deleteUserAccountData() async {
    final uid = _currentUid;
    final currentUser = FirebaseAuth.instance.currentUser;

    // 1. Validação de Segurança Básica
    if (currentUser == null) {
      throw Exception('Nenhum usuário autenticado para excluir.');
    }

    // 2. Apaga Firestore
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      throw Exception('Erro ao excluir dados do banco: $e');
    }

    // 3. Apaga Storage
    try {
      await _storage.ref().child('profile_images').child('$uid.jpg').delete();
    } catch (_) {
      // Ignora silenciosamente, pois o usuário pode não ter foto salva
    }

    // 4. APAGA O AUTH (Com tratamento do bloqueio do Firebase)
    try {
      await currentUser.delete(); 
    } on FirebaseAuthException catch (e) {
      // A trava de segurança mais chata (e importante) do Firebase
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
