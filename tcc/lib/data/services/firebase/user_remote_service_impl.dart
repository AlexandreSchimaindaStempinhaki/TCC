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

    await _firestore.collection('users').doc(uid).delete();

    try {
      final ref = _storage.ref().child('profile_images').child('$uid.jpg');
      await ref.delete();
    } catch (_) {}
  }
}
