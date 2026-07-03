import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(name);

    final userModel = UserModel(
      uid: cred.user!.uid,
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection('users')
        .doc(cred.user!.uid)
        .set(userModel.toMap());

    return userModel;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return getUserProfile(cred.user!.uid);
  }

  Future<UserModel> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);

    final docRef = _firestore.collection('users').doc(cred.user!.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      final userModel = UserModel(
        uid: cred.user!.uid,
        name: cred.user!.displayName ?? 'FinWise User',
        email: cred.user!.email ?? '',
        photoUrl: cred.user!.photoURL,
        createdAt: DateTime.now(),
      );
      await docRef.set(userModel.toMap());
      return userModel;
    }
    return UserModel.fromMap(doc.data()!, cred.user!.uid);
  }

  Future<void> forgotPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserModel> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User profile not found');
    return UserModel.fromMap(doc.data()!, uid);
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
